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
in a home directory that, from the perspective of our cucumber tests, is not our home directory and completely under the conrol
of the tests but, from the perspective of the `fullstop` app, is the user's bona-fide home directory.

We can easily fake this by changing the environment variable `$HOME` just for the tests.  As long as `bin/fullstop` uses this
environment variable to access the user's home directory (which is perfectly valid), everything will be OK.

To do that, we need to modify some of cucumber's plumbing.  Methadone won't do this for you, since it's not applicable to every
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
as we have done with the `$RUBYLIB` environment variable (incidentally, this is how Aruba can run our app without using `bundle
exec`).

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
do that next.  We're going to move a bit faster here, since the specifics of implementing cucumber steps is orthogonal to
Methadone, and we don't want to stray too far from our goal of learning Methadone.  If you'd like
to explore this in more detail, check out the testing chapter of [my book][clibook].

[clibook]: http://www.awesomecommandlineapps.com

Here's the code to implement these steps, which I've put in `features/step_definitions/fullstop_steps.rb`:

```ruby
include FileUtils

FILES = %w(.vimrc .bashrc .exrc)

Given /^a git repo with some dotfiles at "([^"]*)"$/ do |repo_dir|
  @repo_dir = repo_dir
  base_dir = File.dirname(repo_dir)
  dir = File.basename(repo_dir)
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

In short, we set up a fake git repo in our first step definition, using the `FILES` constant so all steps know which files to expect. In our second step definition, we make sure to expand the "~" into `ENV['HOME']` before checking for the cloned repo.  In the last step we check that the files in `ENV['HOME']` are symlinks (being sure to use `lstat` instead of `stat`, as `stat` follows symlinks and will report the files as normal files). 

You won't be familiar with the method `sh` that we're using to call `git`.  This is provided by Methadone and we'll explore it in more detail later.  For now, it functions similarly to `system`.

We should now have a failing test:

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

This is the step that's failing:

```cucumber
Then the dotfiles should be checked out in the directory "~/dotfiles"
```

It's a bit hard to understand *why* it's failing, but the error message and line number helps.  This is the line that's failing:

```ruby
File.exist?(dotfiles_dir).should == true
```

Since `dotfiles_dir` is `~/dotfiles` (or, more specifically, `File.join(ENV['HOME'],'dotfiles')`), and it doesn't exist, since we
haven't written any code that might cause it to exist, the test fails.  Although it's outside the scope of this tutorial, you
should consider writing some custom RSpec matchers for your assertions, since they can allow you to produce better failure
messages.

Now that we have a failing test, we can start writing some code.  This is the first bit of actual logic we'll write, and we need
to revisit the canonical structure of a Methadone app to know where to put it.

Recall that the second part of our app is the "main" block, and it's intended to hold the primary logic of your application.  Methadone provides the method `main`, which lives in `Methadone::Main`, and takes a block.  This block is where you put your logic.  Think of it like the `main` method of a C program.

Now that we know where to put our code, we need to know *what* code we need to add.  To make this step pass, we need to clone the
repo given to us on the command-line.  To do that we need:

* The ability to execute `git`
* The ability to change to the user's home directory
* Access to the repo's URL from the command line

Although we can use `system` or the backtick operator to call `git`, we're going to use `sh`, which is available by mixing in
`Methadone::SH`.  We'll go into the advantages of why we might want to do that later in the tutorial, but for now, think of it as
saving us a few characters over `system`.

We can change to the user's home directory using the `chdir` method of `Dir`, which is built-in to Ruby.  To get the value of the
URL the user provided on the command-line, we could certainly take it from `ARGV`, but Methadone allows you `main` block to take
arguments, which it will populate with the contents of `ARGV`.  All we need to do is change our `main` block to accept `repo_url`
as an argument.

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

Note that all we're doing here is getting the currently-failing step to pass.  We *aren't* implementing the entire app.  We want
to write only the code we need to, and we go one step at a time.  Let's re-run our scenario and see if we get farther:

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

We're now failing at the next step:

```cucumber
And the files in "~/dotfiles" should be symlinked in my home directory
```

The error, "No such file or directory - .vimrc", is being raised from `File.lstat` (as opposed to an explicit test failure).
This is enough to allow us to write some more code.  What we need to do know is iterate over the files in the cloned repo and
symlink them to the user's home directory.  The tools to do this are already available to use via the built-in Ruby library
`FileUtils`.  We'll require it and implement the symlinking logic:

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

Now, let's run our scenario again:

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

Everything passed!  Our app now works for the "happy path".  As long as the user starts from a clean home directory, `fullstop`
will clone their dotfiles, and setup symlinks to them in their home directory.  Now that we have the basics of our app running, we'll see how Methadone makes it easy to add new features.
