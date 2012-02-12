# The Happy Path

We just used TDD and Methadone to create the basics of the user interface for our application.  Now, we need to actually
implement it!  Let's focus on the "happy path", i.e. the way the app will work if nothing goes wrong.  Since we're doing
everything test-first, let's write a new scenario for how the app should work.

We'll append this to `features/fullstop.feature`:

```cucumber
  Scenario: Happy Path
    Given a git repo with some dotfiles at "/tmp/dotfiles.git"
    When I successfully run "fullstop file:///tmp/dotfiles.git"
    Then the dotfiles should be checked out in the directory "~/dotfiles"
    And the files in "~/dotfiles" should be symlinked in my home directory
```

Basically, what we're doing is assuming a git repository in `/tmp/dotfiles.git`, which we then expect `fullstop` to clone,
followed by symlinking the contents to our home directory.  There is, however, a slight problem.

Suppose we make this scenario pass.  This means that *every* time we run this scenario, our dotfiles in our *actual* home
directory will be blown away.  Yikes!  We don't want that; we want our test as isolated as it can be.  What we'd like is to work
in a home directory that, from the perspective of our cucumber tests, is faked out, but from the perspective of `fullstop`, is
the user's bona-fide home directory.

We can easily fake this by changing the environment variable `$HOME` just for the tests.  As long as `bin/fullstop` uses this
envrionment variable to access the user's home directory (which is perfectly valid), everything will be OK.

To do that, we need to modify some of cucumber's plumbing.  Methadone doesn't do this for you, since it's not applicable to every
situation or app.  Open up `features/support/env.rb`.  It should look like this:

```ruby
require 'aruba/cucumber'
require 'methadone/cucumber'

ENV['PATH'] = "#{File.expand_path(File.dirname(__FILE__) + '/../../bin')}#{File::PATH_SEPARATOR}#{ENV['PATH']}"
LIB_DIR = File.join(File.expand_path(File.dirname(__FILE__)),'..','..','lib')

Before do
  # Using "announce" causes massive warnings on 1.9.2
  @puts = true
  @original_rubylib = ENV['RUBYLIB']
  ENV['RUBYLIB'] = LIB_DIR + File::PATH_SEPARATOR + ENV['RUBYLIB'].to_s
end

After do
  ENV['RUBYLIB'] = @original_rubylib
end
```

There's a lot in there already to make our tests work and, fortunately, it makes our job of faking the home directory a bit
easier.  We need to save the original location in `Before`, and then change it there, setting it back to normal in `After`, just
as we have done with the `$RUBYLIB` envrionment variable.

```ruby
require 'aruba/cucumber'
require 'methadone/cucumber'

ENV['PATH'] = "#{File.expand_path(File.dirname(__FILE__) + '/../../bin')}#{File::PATH_SEPARATOR}#{ENV['PATH']}"
LIB_DIR = File.join(File.expand_path(File.dirname(__FILE__)),'..','..','lib')

Before do
  # Using "announce" causes massive warnings on 1.9.2
  @puts = true
  @original_rubylib = ENV['RUBYLIB']
  ENV['RUBYLIB'] = LIB_DIR + File::PATH_SEPARATOR + ENV['RUBYLIB'].to_s
  # vvv
  @original_home = ENV['HOME']
  ENV['HOME'] = "/tmp/fakehome"
  FileUtils.rm_rf "/tmp/fakehome"
  FileUtils.mkdir "/tmp/fakehome"
  # ^^^
end

After do
  ENV['RUBYLIB'] = @original_rubylib
  # vvv
  ENV['HOME'] = @original_home
  # ^^^
end
```

As you can see, we also delete the directory and re-create it so that anything leftover from a previous test won't cause false
positives or negatives in our tests.

*Now*, let's run our scenario and see where we're at:


```sh
$ rake features
Feature: Checkout dotfiles
  In order to get my dotfiles onto a new computer
  I want a one-command way to keep them up to date
  So I don't have to do it myself

  Scenario: Basic UI
    When I get help for "fullstop"
    Then the exit status should be 0
    And the banner should be present
    And there should be a one line summary of what the app does
    And the banner should include the version
    And the banner should document that this app takes options
    And the banner should document that this app's arguments are:
      | repo_url | which is required |

  Scenario: Happy Path
    Given a git repo with some dotfiles at "/tmp/dotfiles.git"
    When I successfully run "fullstop file:///tmp/dotfiles.git"
    Then the dotfiles should be checked out in the directory "~/dotfiles"
    And the files in "~/dotfiles" should be symlinked in my home directory

2 scenarios (1 undefined, 1 passed)
11 steps (1 skipped, 3 undefined, 7 passed)
0m0.152s

You can implement step definitions for undefined steps with these snippets:

Given /^a git repo with some dotfiles at "([^"]*)"$/ do |arg1|
  pending # express the regexp above with the code you wish you had
end

Then /^the dotfiles should be checked out in the directory "([^"]*)"$/ do |arg1|
  pending # express the regexp above with the code you wish you had
end

Then /^the files in "([^"]*)" should be symlinked in my home directory$/ do |arg1|
  pending # express the regexp above with the code you wish you had
end
```

As you can see there are three steps that cucumber doesn't know how to execute.  It provides boilerplate for doing so, so let's
do that next.  As this is more about Aruba and Ruby, and less about Methadone, we'll go a bit fast here.  You can 
explore this sort of technique in more detail in [my book][clibook], but here's how we'll implement these steps:

```ruby
include FileUtils

FILES = %w(.vimrc .bashrc .exrc)

Given /^a git repo with some dotfiles at "([^"]*)"$/ do |repo_dir|
  @repo_dir = repo_dir
  base_dir = File.dirname(repo_dir)
  dir = File.basename(repo_dir)
  puts base_dir
  puts dir
  Dir.chdir base_dir do
    rm_rf dir
    mkdir dir
  end
  Dir.chdir repo_dir do
    FILES.each { |_| touch _ }
    sh "git init ."
    sh "git add #{FILES.join(' ')}"
    sh "git commit -a -m 'initial commit'"
  end
end

Then /^the dotfiles should be checked out in the directory "([^"]*)"$/ do |dotfiles_dir|
  # Expand ~ to ENV["HOME"]
  base_dir = File.dirname(dir)
  base_dir = ENV['HOME'] if base_dir == "~"
  dotfiles_dir = File.join(base_dir,File.basename(dotfiles_dir))

  File.exist?(dotfiles_dir).should == true
  Dir.chdir dotfiles_dir do
    FILES.each do |file|
      File.exist?(file).should == true
    end
  end
end

Then /^the files in "([^"]*)" should be symlinked in my home directory$/ do |dotfiles_dir|
  Dir.chdir(ENV['HOME']) do
    FILES.each do |file|
      File.lstat(file).should be_symlink
    end
  end
end
```

In short, we set up a fake git repo in our first step definition, using the `FILES` constant to make things easier.  In our second step definition, we make sure to expand the "~" into `ENV['HOME']` before checking for the cloned repo, and in the last step we check that the files in `ENV['HOME']` are symlinks (being sure to use `lstat` instead of `stat`, as `stat` follows symlinks). Finally, you might not be familiar with the method `sh` that we're using to call `git`.  This is provided by Methadone and we'll explore it in more detail later.  For now, it functions similarly to `system`.

Now, we should have a failing test:

```sh
$ rake features
Feature: Checkout dotfiles
  In order to get my dotfiles onto a new computer
  I want a one-command way to keep them up to date
  So I don't have to do it myself

  Scenario: Basic UI
    When I get help for "fullstop"
    Then the exit status should be 0
    And the banner should be present
    And there should be a one line summary of what the app does
    And the banner should include the version
    And the banner should document that this app takes options
    And the banner should document that this app's arguments are:
      | repo_url | which is required |

  Scenario: Happy Path
    Given a git repo with some dotfiles at "/tmp/dotfiles.git"
    When I successfully run `fullstop file:///tmp/dotfiles.git`
      Then the dotfiles should be checked out in the directory "~/dotfiles"
      expected: true
           got: false (using ==) (RSpec::Expectations::ExpectationNotMetError)
      ./features/step_definitions/fullstop_steps.rb:29:in `/^the dotfiles should be checked out in the directory "([^"]*)"$/'
      features/fullstop.feature:19:in `Then the dotfiles should be checked out in the directory "~/dotfiles"'
    And the files in "~/dotfiles" should be symlinked in my home directory

Failing Scenarios:
cucumber features/fullstop.feature:16

2 scenarios (1 failed, 1 passed)
11 steps (1 failed, 1 skipped, 9 passed)
0m0.291s
rake aborted!
Cucumber failed

Tasks: TOP => features
(See full trace by running task with --trace)
```

The error is that the directory `~/dotfiles` (after replacing `~` with `ENV['HOME']` doesn't exist.  This shouldn't be surprising, since we haven't written any code.  Let's do so.

This is our first time adding logic unrelated to the UI, and it requires a slight detour on the organization of a
Methadone-powered command-line app.

Since a Ruby executable executes from top to bottom, we'd normally need to have all of our main logic at the end of the file.
This is the most interest and relevant part of the file, and it woudl be nice if this were as close to the top as possible, so we
see it when we open the file.

Methadone provides the method `main`, which lives in `Methadone::Main`, and takes a block.  This block should be thought of as
your *main* method of your program.  The block is given all of the arguments unparsed on the command-line, so it behaves very
similarly to a true main method that you might see in C.

Given that, we'll do the followingn things to pass the currently-failing step:

* Include `Methadone::SH`, which provides a nice way to call external commands (we'll explain more about it in a moment)
* Change the `main` block so it takes and argument, the `repo_url`
* Change to the user's home directory and clone the repo

Here's the code:

```ruby
#!/usr/bin/env ruby

require 'optparse'
require 'methadone'
require 'fullstop'

class App
  include Methadone::Main
  include Methadone::CLILogging
  # vvv
  include Methadone::SH
  # ^^^

  #        vvv
  main do |repo_url|
    #      ^^^
    
    # vvv
    Dir.chdir ENV['HOME'] do
      sh "git clone #{repo_url}"
    end
    # ^^^
  end

  version Fullstop::VERSION

  description 'Manages dotfiles from a git repo'

  arg :repo_url

  use_log_level_option

  go!
end
```

Again, think of `sh` as a shorter (and, as we'll see later on, better) version of `system`.  We now see that we get farther in
our test:

```sh
rake features
Feature: Checkout dotfiles
  In order to get my dotfiles onto a new computer
  I want a one-command way to keep them up to date
  So I don't have to do it myself

  Scenario: Basic UI
    When I get help for "fullstop"
    Then the exit status should be 0
    And the banner should be present
    And there should be a one line summary of what the app does
    And the banner should include the version
    And the banner should document that this app takes options
    And the banner should document that this app's arguments are:
      | repo_url | which is required |

  Scenario: Happy Path
    Given a git repo with some dotfiles at "/tmp/dotfiles.git"
    When I successfully run `fullstop file:///tmp/dotfiles.git`
    Then the dotfiles should be checked out in the directory "~/dotfiles"
    And the files in "~/dotfiles" should be symlinked in my home directory
      No such file or directory - .vimrc (Errno::ENOENT)
      ./features/step_definitions/fullstop_steps.rb:40:in `lstat'
      ./features/step_definitions/fullstop_steps.rb:40:in `block (3 levels) in <top (required)>'
      ./features/step_definitions/fullstop_steps.rb:39:in `each'
      ./features/step_definitions/fullstop_steps.rb:39:in `block (2 levels) in <top (required)>'
      ./features/step_definitions/fullstop_steps.rb:38:in `chdir'
      ./features/step_definitions/fullstop_steps.rb:38:in `/^the files in "([^"]*)" should be symlinked in my home directory$/'
      features/fullstop.feature:20:in `And the files in "~/dotfiles" should be symlinked in my home directory'

Failing Scenarios:
cucumber features/fullstop.feature:16

2 scenarios (1 failed, 1 passed)
11 steps (1 failed, 10 passed)
0m0.313s
rake aborted!
Cucumber failed

Tasks: TOP => features
(See full trace by running task with --trace)
```

Instead of complaining that `~/dotfiles` didn't exist, it's now complaining that `.vimrc` isn't symlinked in our home directory.
That makes sense, since our app just does the `git clone`.  Let's symlink everything using `ln_s` from `FileUtils`:

```ruby
#!/usr/bin/env ruby

require 'optparse'
require 'methadone'
require 'fullstop'
# vvv
require 'fileutils'
# ^^^

class App
  include Methadone::Main
  include Methadone::CLILogging
  include Methadone::SH

  main do |repo_url|
    
    Dir.chdir ENV['HOME'] do
      sh "git clone #{repo_url}"
      basedir = repo_url.split(/\//)[-1].gsub(/\.git$/,'')
      # vvv
      Dir.entries(basedir).each do |file|
        next if file == '.' || file == '..' || file == '.git'
        FileUtils.ln_s file,'.'
      end
      # ^^^
    end
  end

  version Fullstop::VERSION

  description 'Manages dotfiles from a git repo'

  arg :repo_url

  use_log_level_option

  go!
end
```

This is pretty straightfoward, and we can see that our scenario passes!

```sh
$ rake features
Feature: Checkout dotfiles
  In order to get my dotfiles onto a new computer
  I want a one-command way to keep them up to date
  So I don't have to do it myself

  Scenario: Basic UI
    When I get help for "fullstop"
    Then the exit status should be 0
    And the banner should be present
    And there should be a one line summary of what the app does
    And the banner should include the version
    And the banner should document that this app takes options
    And the banner should document that this app's arguments are:
      | repo_url | which is required |

  Scenario: Happy Path
    Given a git repo with some dotfiles at "/tmp/dotfiles.git"
    When I successfully run `fullstop file:///tmp/dotfiles.git`
    Then the dotfiles should be checked out in the directory "~/dotfiles"
    And the files in "~/dotfiles" should be symlinked in my home directory

2 scenarios (2 passed)
11 steps (11 passed)
0m0.396s
```

Now that we have the basics of our app running, we'll see how Methadone makes it easy to add new features.
