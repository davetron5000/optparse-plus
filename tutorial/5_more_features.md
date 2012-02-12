# Adding Features

Our command-line app isn't very interesting at this point; it's more of a glorified shell script.  Where Ruby and Methadone
really shine is when things start getting complex.  There's a lot of features we can add and error cases we can handle, for
example:

* The app will blow up if the git repo is already cloned
* The app might blow up if the files are already symlinked
* The app won't symlink new files
* The app checks out your dotfiles repo in your home directory
* The app uses symlinks, but we might want copies instead

You can probably think of even more features.  To demonstrate how Methadone works, we're going to add these features:

* a "force" switch that will blow away the git repo and re-clone it
* a "location" flag that will allow us to control where the repo gets clone

We'll do this by adding a switch `--force` that will trigger the "blow away the repo" function.  We'll also add a flag
`--checkout-dir` that will take an argument for where we should do the checkout.  It will also be available via `-d` for the
convienience of command-line users (see [my book][clibook] to understand why we might want to provide both short and long-form
options).

First, let's test-drive our new user interface by updating our "Basic UI" scenario to look like so:

```cucumber
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
      |repo_url|which is required|
    And the following options should be documented:
      | --force        |
      | --checkout-dir |
      | -d             |

  Scenario: Happy Path
    Given a git repo with some dotfiles at "/tmp/dotfiles.git"
    When I successfully run `fullstop file:///tmp/dotfiles.git`
    Then the dotfiles should be checked out in the directory "~/dotfiles"
    And the files in "~/dotfiles" should be symlinked in my home directory
```

We've added the step "And the following options should be documented".  This will allow us to write the code necessary to handle
these options.  First, we'll run our tests to see that we have a failing scenario:

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
    And the following options should be documented:
      | --force        |
      | --checkout-dir |
      | -d             |
      expected: /^\s*--force\s+\w\w\w+/m
           got: "Usage: fullstop [options] repo_url\n\nManages dotfiles from a git repo\n\nv0.0.1\n\nOptions:\n        --version                    Show help/version info\n        --log-level LEVEL            Set the logging level (debug|info|warn|error|fatal)\n                                     (Default: info)\n" (using =~)
      Diff:
      @@ -1,2 +1,11 @@
      -/^\s*--force\s+\w\w\w+/m
      +Usage: fullstop [options] repo_url
      +
      +Manages dotfiles from a git repo
      +
      +v0.0.1
      +
      +Options:
      +        --version                    Show help/version info
      +        --log-level LEVEL            Set the logging level (debug|info|warn|error|fatal)
      +                                     (Default: info)
       (RSpec::Expectations::ExpectationNotMetError)
      features/fullstop.feature:15:in `And the following options should be documented:'

  Scenario: Happy Path
    Given a git repo with some dotfiles at "/tmp/dotfiles.git"
    When I successfully run `fullstop file:///tmp/dotfiles.git`
    Then the dotfiles should be checked out in the directory "~/dotfiles"
    And the files in "~/dotfiles" should be symlinked in my home directory

Failing Scenarios:
cucumber features/fullstop.feature:6

2 scenarios (1 failed, 1 passed)
12 steps (1 failed, 11 passed)
0m0.574s
rake aborted!
Cucumber failed

Tasks: TOP => features
(See full trace by running task with --trace)
```

As you can see, our tests are failing, because the documentation of the existence of our command-line option couldn't be found in
the help output.

To make this test pass in an `OptionParser` driven application, you might write something like this:

```ruby
options = {
  'checkout-dir' => ENV['HOME'],
}
parser = OptionParser.new do |opts|
  opts.on("--force","Force overwriting existing files") do 
    options[:force] = true
  end
  opts.on("-d DIR","--checkout-dir",
          "Set the location of the checkout dir",
          "(default: #{options['checkout-dir']})") do |dir|
    options['checkout-dir'] = dir
  end
end
parser.parse!
```

This is pretty tedious; when we parse command-line options, we almost always want to put the value of the option into a hash to
inspect later during the execution of our program.  As we've mentioned, Methadone manages an instance of `OptionParser` that we
can use.  We could write the above code almost exactly as written, and it would work fine, however Methadone provides more.

Methadone's `Methadone::Main` module includes what is essentially a proxy to the managed `OptionParser` with various convienience
methods built-in.    The one we want is called `on` and works just like the `on` method of `OptionParser`, with a few additional
defaults.

Before we see that, we need to *also* mention that Methadone manages a `Hash` into which our parsed options will be placed.  This
`Hash` is available via the method `options`.  This method is available inside and outside of our `main` block, so we can use it
to set defaults when declaring our UI, and we can use it to get the values the user specified on the command-line inside `main`.

With all of that information, we can bring together how `on` works.  `on` will pass all of its command-line arguments to the `on`
method of the underlying `OptionParser` instance, but will do two additional things:

* If you do *not* pass a block to `on`, it will provide `OptionParser` a block that sets the value of the command-line option inside the `options` hash.
* If there is a default value for your option, it will be included in the help string.

In other words, the above code, written against `OptionParser`, would look like this, in Methadone:


```ruby
options['checkout-dir'] = ENV['HOME']

on("--force","Force overwriting of existing files")
on("-d DIR","--checkout-dir","Set the location of the checkout dir")
```

That's it!  14 lines become 3.  When `main` executes, the following keys in `options` will be available:

* `"force"` - true if the user specified `--force`
* `:force` - the same
* `"d"` - the value of the checkout dir (as given to `-d` or `--force`), or the default, i.e. not `nil`
* `:d` - the same
* `"checkout-dir"` - the same
* `:'checkout-dir'` - the same

Notice that each flag is available as a `String` or `Symbol` and that all forms of each option are present.

Coming back to our app, let's add this code and see if our test passes.  Here's what `bin/fullstop` looks like now:

```ruby
#!/usr/bin/env ruby

require 'optparse'
require 'methadone'
require 'fullstop'
require 'fileutils'

class App
  include Methadone::Main
  include Methadone::CLILogging
  include Methadone::SH

  main do |repo_url|
    
    #         vvv
    Dir.chdir options['checkout-dir'] do
      #       ^^^
      sh "git clone #{repo_url}"
      basedir = repo_url.split(/\//)[-1].gsub(/\.git$/,'')
      Dir.entries(basedir).each do |file|
        next if file == '.' || file == '..' || file == '.git'
        FileUtils.ln_s file,'.'
      end
    end
  end

  version Fullstop::VERSION

  description 'Manages dotfiles from a git repo'

  # vvv
  options['checkout-dir'] = ENV['HOME']
  on("--force","Overwrite files if they exist")
  on("-d DIR","--checkout-dir","Where to clone the repo")
  # ^^^

  arg :repo_url

  use_log_level_option

  go!
end
```

We've highlighted the lines we changed.  Note that, because we added the option to change the checkout dir, we started using it
inside `main`.  If we wanted to be very strict in our TDD, we would've written a test for that, but that's a bit outside the
scope of Methadone (feel free to do this on your own, however!).

Now, we can see that our test passes, *and* our other scenario doesn't fail, meaning we didn't introduce any bugs.

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
    And the following options should be documented:
      | --force        |
      | --checkout-dir |
      | -d             |

  Scenario: Happy Path
    Given a git repo with some dotfiles at "/tmp/dotfiles.git"
    When I successfully run `fullstop file:///tmp/dotfiles.git`
    Then the dotfiles should be checked out in the directory "~/dotfiles"
    And the files in "~/dotfiles" should be symlinked in my home directory

2 scenarios (2 passed)
12 steps (12 passed)
0m0.398s
```

We can also see the UI that's generated by this small amount of code:

```sh
$ bundle exec bin/fullstop --help
Usage: fullstop [options] repo_url

Manages dotfiles from a git repo

v0.0.1

Options:
        --version                    Show help/version info
        --force                      Overwrite files if they exist
    -d, --checkout-dir DIR           Where to clone the repo
                                     (default: /Users/davec)
        --log-level LEVEL            Set the logging level (debug|info|warn|error|fatal)
                                     (Default: info)
```

Take a moment to reflect on everything you're getting.  We specify only the names of options and their description, and Methadone
handles the rest.  *And*, you can avoid all of this magic entirely, if you really need to, since you have access to the
`OptionParser` instance via the `opts` method.

For completeness, let's go ahead an implement the two features now that we have the UI in place.  To do this, we'll create two
new scenarios.

First, let's implement the `--force` flag with the following scneario:

```cucumber
  Scenario: Force overwrite
    Given a git repo with some dotfiles at "/tmp/dotfiles.git"
    And I have my dotfiles cloned and symlinked to "~/dotfiles"
    And there's a new file in the git repo
    When I run `fullstop --force file:///tmp/dotfiles.git`
    Then the dotfiles in "~/dotfiles" should be re-cloned
    And the files in "~/dotfiles" should be symlinked in my home directory
```

Several of these steps aren't there, so we'll have to implement them ourselves.  Rather than get wrapped up into
that, let's focus on getting our app to pass this scenario.  Supposing these steps are implemented, we now have a failing
scenario:

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
    And the following options should be documented:
      | --force        |
      | --checkout-dir |
      | -d             |

  Scenario: Happy Path
    Given a git repo with some dotfiles at "/tmp/dotfiles.git"
    When I successfully run `fullstop file:///tmp/dotfiles.git`
    Then the dotfiles should be checked out in the directory "~/dotfiles"
    And the files in "~/dotfiles" should be symlinked in my home directory

  Scenario: Force overwrite
    Given a git repo with some dotfiles at "/tmp/dotfiles.git"
    And I have my dotfiles cloned and symlinked to "~/dotfiles"
    And there's a new file in the git repo
    When I run `fullstop --force file:///tmp/dotfiles.git`
    Then the dotfiles in "~/dotfiles" should be re-cloned
      expected: true
           got: false (using ==) (RSpec::Expectations::ExpectationNotMetError)
      ./features/step_definitions/fullstop_steps.rb:35:in `block (3 levels) in <top (required)>'
      ./features/step_definitions/fullstop_steps.rb:33:in `each'
      ./features/step_definitions/fullstop_steps.rb:33:in `block (2 levels) in <top (required)>'
      ./features/step_definitions/fullstop_steps.rb:32:in `chdir'
      ./features/step_definitions/fullstop_steps.rb:32:in `/^the dotfiles should be checked out in the directory "([^"]*)"$/'
      features/fullstop.feature:31:in `Then the dotfiles in "~/dotfiles" should be re-cloned'
    And the files in "~/dotfiles" should be symlinked in my home directory

Failing Scenarios:
cucumber features/fullstop.feature:26

3 scenarios (1 failed, 2 passed)
18 steps (1 failed, 1 skipped, 16 passed)
0m0.703s
rake aborted!
Cucumber failed

Tasks: TOP => features
(See full trace by running task with --trace)
```

We're failing because the new file we added to our repo after the initial clone can't be found.  It's likely that our second
clone failed, but we didn't notice, because we aren't checking.  If we run our app manually, we can see that errors are flying,
but we aren't checking:

```sh
$ HOME=/tmp/fake-home bundle exec bin/fullstop file:///tmp/dotfiles.git
$ HOME=/tmp/fake-home bundle exec bin/fullstop file:///tmp/dotfiles.git
Error output of 'git clone file:///tmp/dotfiles.git': fatal: destination path 'dotfiles' already exists and is not an empty directory.
Output of 'git clone file:///tmp/dotfiles.git': 
Error running 'git clone file:///tmp/dotfiles.git'
File exists - (.bashrc, ./.bashrc)
$ echo $?
70
```

We can see that error output is being produced from `git`, but we're ignoring it.  `fullstop` fails later in the process when we
ask it to symlink files that already exist.  This is actually a bug, so let's take a short detour and fix
this problem.  When doing TDD, it's important to know how your app is failing, so you can be confident that the code you are
about to write fixes the correct failing in the existing app.

We'll write a scenario to reveal the bug:

```cucumber
  Scenario: Fail if directory is cloned
    Given a git repo with some dotfiles at "/tmp/dotfiles.git"
    And I have my dotfiles cloned and symlinked to "~/dotfiles"
    And there's a new file in the git repo
    When I run `fullstop file:///tmp/dotfiles.git`
    Then the exit status should not be 0
    And the stderr should contain "checkout dir already exists, use --force to overwrite"
```

Now, we can see that it doesn't pass:
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
    And the following options should be documented:
      | --force        |
      | --checkout-dir |
      | -d             |

  Scenario: Happy Path
    Given a git repo with some dotfiles at "/tmp/dotfiles.git"
    When I successfully run `fullstop file:///tmp/dotfiles.git`
    Then the dotfiles should be checked out in the directory "~/dotfiles"
    And the files in "~/dotfiles" should be symlinked in my home directory

  Scenario: Fail if directory is cloned
    Given a git repo with some dotfiles at "/tmp/dotfiles.git"
    And I have my dotfiles cloned and symlinked to "~/dotfiles"
    And there's a new file in the git repo
    When I run `fullstop file:///tmp/dotfiles.git`
    Then the exit status should not be 0
    And the stderr should contain "checkout dir already exists, uses --force to overwrite"
      expected "W, [2012-02-12T15:12:35.720851 #43530]  WARN -- : Error output of 'git clone file:///tmp/dotfiles.git': fatal: destination path 'dotfiles' already exists and is not an empty directory.\nW, [2012-02-12T15:12:35.720964 #43530]  WARN -- : Error running 'git clone file:///tmp/dotfiles.git'\nE, [2012-02-12T15:12:35.721503 #43530] ERROR -- : File exists - (.bashrc, ./.bashrc)\n" to include "checkout dir already exists, uses --force to overwrite"
      Diff:
      @@ -1,2 +1,4 @@
      -["checkout dir already exists, uses --force to overwrite"]
      +W, [2012-02-12T15:12:35.720851 #43530]  WARN -- : Error output of 'git clone file:///tmp/dotfiles.git': fatal: destination path 'dotfiles' already exists and is not an empty directory.
      +W, [2012-02-12T15:12:35.720964 #43530]  WARN -- : Error running 'git clone file:///tmp/dotfiles.git'
      +E, [2012-02-12T15:12:35.721503 #43530] ERROR -- : File exists - (.bashrc, ./.bashrc)
       (RSpec::Expectations::ExpectationNotMetError)
      features/fullstop.feature:32:in `And the stderr should contain "checkout dir already exists, uses --force to overwrite"'

Failing Scenarios:
cucumber features/fullstop.feature:26

3 scenarios (1 failed, 2 passed)
18 steps (1 failed, 17 passed)
0m0.694s
rake aborted!
Cucumber failed

Tasks: TOP => features
(See full trace by running task with --trace)
```

It looks like `fullstop` is writing log messages.  It is, and we'll talk about that more later, but right now, we need to focus
on the fact that we aren't producing the error message we expect.  Let's modify `bin/fullstop` to check that the call to `git`
succeeded.  `sh` returns the exit status of the command it calls, so we can use that to fix things.

Here's the changes we'l l make to `bin/fullstop` to check for this:

```ruby
#!/usr/bin/env ruby

require 'optparse'
require 'methadone'
require 'fullstop'
require 'fileutils'

class App
  include Methadone::Main
  include Methadone::CLILogging
  include Methadone::SH

  main do |repo_url|
    
    Dir.chdir options['checkout-dir'] do
      #                              vvv
      if sh("git clone #{repo_url}") == 0
        #                            ^^^
        basedir = repo_url.split(/\//)[-1].gsub(/\.git$/,'')
        Dir.entries(basedir).each do |file|
          next if file == '.' || file == '..' || file == '.git'
          FileUtils.ln_s file,'.'
        end
      else
        # vvv
        exit_now!("checkout dir already exists, use --force to overwrite")
        # ^^^
      end
    end
  end

  version Fullstop::VERSION

  description 'Manages dotfiles from a git repo'

  options['checkout-dir'] = ENV['HOME']
  on("--force","Overwrite files if they exist")
  on("-d DIR","--checkout-dir","Where to clone the repo")

  arg :repo_url

  use_log_level_option

  go!
end
```

Since an exit of zero is considered success, we branch on that value, and call the method `exit_now!`, provided by Methadone, to
stop the app with an error.  The argument is an error message to
print to the standard error to let the user know why the app stopped abnormally.  The app will then stop and exit nonzero.  If
you want to customize the exit code, you can provide it as the first argument, with the message being the second argument.

As you can see, our test now passes:

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
    And the following options should be documented:
      | --force        |
      | --checkout-dir |
      | -d             |

  Scenario: Happy Path
    Given a git repo with some dotfiles at "/tmp/dotfiles.git"
    When I successfully run `fullstop file:///tmp/dotfiles.git`
    Then the dotfiles should be checked out in the directory "~/dotfiles"
    And the files in "~/dotfiles" should be symlinked in my home directory

  Scenario: Fail if directory is cloned
    Given a git repo with some dotfiles at "/tmp/dotfiles.git"
    And I have my dotfiles cloned and symlinked to "~/dotfiles"
    And there's a new file in the git repo
    When I run `fullstop file:///tmp/dotfiles.git`
    Then the exit status should not be 0
    And the stderr should contain "checkout dir already exists, use --force to overwrite"

3 scenarios (3 passed)
18 steps (18 passed)
0m0.789s
```

NOW, we can get back to the `--force` flag.  We're going to change our scenario a bit, as well.  Instead of using "When I run `fullstop --force file:///tmp/dotfiles.git`" we'll use "When I successfully run `fullstop --force file:///tmp/dotfiles.git`", which will fail if the app exits nonzero.  This will cause our scenario to fail earlier.

To fix this, we'll change the code in `bin/fullstop` so that if the user specified `--force`, we'll delete the directory before we
clone.  We'll also need to delete the files that were symlinked in the home directory as well.

```ruby
#!/usr/bin/env ruby

require 'optparse'
require 'methadone'
require 'fullstop'
require 'fileutils'

class App
  include Methadone::Main
  include Methadone::CLILogging
  include Methadone::SH

  main do |repo_url|
    
    Dir.chdir options['checkout-dir'] do
      basedir = repo_url.split(/\//)[-1].gsub(/\.git$/,'')
      # vvv
      if options[:force] && Dir.exists?(basedir)
        warn "deleting #{basedir} before cloning"
        FileUtils.rm_rf basedir
      end
      # ^^^
      if sh("git clone #{repo_url}") == 0
        Dir.entries(basedir).each do |file|
          next if file == '.' || file == '..' || file == '.git'
          source_file = File.join(basedir,file)
          # vvv
          FileUtils.rm(file) if File.exists?(file) && options[:force]
          # ^^^
          FileUtils.ln_s source_file,'.'
        end
      else
        exit_now!("checkout dir already exists, use --force to overwrite")
      end
    end
  end

  version Fullstop::VERSION

  description 'Manages dotfiles from a git repo'

  options['checkout-dir'] = ENV['HOME']
  on("--force","Overwrite files if they exist")
  on("-d DIR","--checkout-dir","Where to clone the repo")

  arg :repo_url

  use_log_level_option

  go!
end
```

Now, we can see that our scenario passes:

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
    And the following options should be documented:
      | --force        |
      | --checkout-dir |
      | -d             |

  Scenario: Happy Path
    Given a git repo with some dotfiles at "/tmp/dotfiles.git"
    When I successfully run `fullstop file:///tmp/dotfiles.git`
    Then the dotfiles should be checked out in the directory "~/dotfiles"
    And the files in "~/dotfiles" should be symlinked in my home directory

  Scenario: Fail if directory is cloned
    Given a git repo with some dotfiles at "/tmp/dotfiles.git"
    And I have my dotfiles cloned and symlinked to "~/dotfiles"
    And there's a new file in the git repo
    When I run `fullstop file:///tmp/dotfiles.git`
    Then the exit status should not be 0
    And the stderr should contain "checkout dir already exists, use --force to overwrite"

  Scenario: Force overwrite
    Given a git repo with some dotfiles at "/tmp/dotfiles.git"
    And I have my dotfiles cloned and symlinked to "~/dotfiles"
    And there's a new file in the git repo
    When I successfully run `fullstop --force file:///tmp/dotfiles.git`
    Then the dotfiles in "~/dotfiles" should be re-cloned
    And the files in "~/dotfiles" should be symlinked in my home directory

4 scenarios (4 passed)
24 steps (24 passed)
0m1.171s
```

We're starting to see a few features of Methadone that need some explanation, such as what those log messages are, and how the
output of our commands is getting there.  But first, our `main` method is also becoming pretty messy.  Since Methadone allows and encourages you to write your app cleanly, we can refactor that code into classes that live inside `lib`.  We'll see how to do that in the next section.
