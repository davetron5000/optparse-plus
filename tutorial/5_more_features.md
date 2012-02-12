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

In the next section, we'll dig deeper into how to do error handling and logging, which are crucial to making a command-line app
that can survive in any environment.
