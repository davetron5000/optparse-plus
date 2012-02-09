# UI

We're taking an [outside-in][outsidein] approach to our app; we'll create a basic user interface based on how it should function,
and then fill in the details.  This will let us focus on our app's usability first, which will result in an overall better app
that users will enjoy and be able to use.  It will also be easier for us to maintain and enhance over time.

Before we dive into our Cucumber features, let's take a moment to think about how our app might work.  Essentially, we want it to
clone a git repository somewhere on disk, and then symlink all of those files and directories in the top level of that repo into
our home directory.  If we did this in `bash` on the command line, it might be something like this:

```sh
$ cd ~
$ git clone git@github.com:davetron5000/dotfiles.git
$ for file in `ls -a dotfiles`; do
> ln -s dotfiles/$file .
> done
```

It's worth pointing out that the reason we don't do this is that our app will be able to update and link new files, but for now, let's just focus on the first case.  To handle this in one command-line app, we simply need to know the git repo of where our dotfiles are.  Let's replace the cucumber test Methadone generated for us with a new one that verifies that our app takes the repo as an argument.

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
```

This scenario describes getting help for our app and the basic user interface that we need.  This is how "test-drive" the
development of the user interface portion of our app.  Let's run the scenario and see what happens.

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
      expected "v0.0.1" to match /^\w\w+\s+\w\w+/ (RSpec::Expectations::ExpectationNotMetError)
      features/fullstop.feature:10:in `And there should be a one line summary of what the app does'
    And the banner should include the version
    And the banner should document that this app takes options
    And the banner should document that this app's arguments are:
      | repo_url | which is required |

Failing Scenarios:
cucumber features/fullstop.feature:6

1 scenario (1 failed)
7 steps (1 failed, 3 skipped, 3 passed)
0m0.126s
rake aborted!
Cucumber failed

Tasks: TOP => features
(See full trace by running task with --trace)
```

We have a failing test!  Note that some things are already passing, despite the fact that we've done no coding.  Also notice that
cucumber didn't complain about unknown steps.  Methadone provides almost all of these cucumber steps for us.  The rest are
provided by Aruba.  Since Methadone generated an executable for us when we ran the `methadone` command, it already provides the
ability to get help, and exits with the correct exit status.

Let's fix things one step at a time, so we can see exactly what we need to do.  The current scenario is failing because our app
doesn't have a one line summary.  This summary is important so that we can remember what the app does later on (despite how
clever our name is, it's likely we'll forget a few months from now and the description will jog our memory).

Let's have a look at our executable.

```ruby
#!/usr/bin/env ruby

require 'optparse'
require 'methadone'
require 'fullstop'

class App
  include Methadone::Main
  include Methadone::CLILogging

  main do

  end

  version Fullstop::VERSION

  use_log_level_option

  go!
end
```

We've omitted the comments so we don't get distracted; Methadone provides some useful pointers inside the generated executable so
you can easily recall the methods you'll need.  We'll learn about them later, but right now we need to add a description of our
app.

In a vanilla Ruby application, we'd use the `banner` method of an `OptionParser` to add this description.  Methadone manages our
`OptionParser` instance and, while we *do* have access to it, and could call `banner` ourselves, Methadone actually does a pretty
good job of creating a nice banner based on meta-data we provide about our app.  For example, the call to `version` is used to
provide Methadone the version of our app so it can appear in the banner.

Methadone provides a convienience method called `description` that takes a single argument: a one-line description of our app.


```ruby
#!/usr/bin/env ruby

require 'optparse'
require 'methadone'
require 'fullstop'

class App
  include Methadone::Main
  include Methadone::CLILogging

  main do 
  end

  version Fullstop::VERSION

  # vvv
  description 'Manages dotfiles from a git repo'
  # ^^^

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
      expected "Usage: fullstop [options]\n\nManages dotfiles from a git repo\n\nv0.0.1\n\nOptions:\n        --version                    Show help/version info\n        --log-level LEVEL            Set the logging level (debug|info|warn|error|fatal)\n                                     (Default: info)\n" to include "repo_url"
      Diff:
      @@ -1,2 +1,11 @@
      -["repo_url"]
      +Usage: fullstop [options]
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
      features/fullstop.feature:13:in `And the banner should document that this app's arguments are:'

Failing Scenarios:
cucumber features/fullstop.feature:6

1 scenario (1 failed)
7 steps (1 failed, 6 passed)
0m0.132s
rake aborted!
Cucumber failed

Tasks: TOP => features
(See full trace by running task with --trace)
```

We got farther this time.  Before we fix the next problem, let's make sure we understand why the steps after the one we just fix are now passing, despite the fact that we didn't explicitly implement those features.  This is the Methadone bootstrapping and app framework helping us.  Just be creating a basic Methadone app, the version will show in the help output, and the usage statement will correctly show the string `[options]`, because Methadone knows that we take options (namely the `--version` and `--log-level`.  If we omitted these options entirely, Methadone would omit the string `[options]` from the usage statement.  

Now, let's fix the last step that's failing.  What Methadone is looking for is for the string `repo_url` (the name of our only,
required, argument) to be in the usage string, in other words, Methadone is expecting to see this:

```
Usage: fullstop [option] repo_url
```

Again, if we were using `OptionParser`, we could hand-jam that, but Methadone provides the method `arg` that allows us to name
our argument.  We'll add that to our executable.

```ruby
#!/usr/bin/env ruby

require 'optparse'
require 'methadone'
require 'fullstop'

class App
  include Methadone::Main
  include Methadone::CLILogging

  main do 
  end

  version Fullstop::VERSION

  description 'Manages dotfiles from a git repo'

  # vvv
  arg :repo_url
  # ^^^

  use_log_level_option

  go!
end
```

Now, when we run our features again, we can see that everything passes:

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

1 scenario (1 passed)
7 steps (7 passed)
0m0.129s
```

Nice!  Now, if our UI should ever change, we'll notice the regression, and we have a very easy way to use TDD to create our
application's UI.  Let's take a look at it ourselves to see what it's like:

```sh
$ bundle exec bin/fullstop --help
Usage: fullstop [options] repo_url

Manages dotfiles from a git repo

v0.0.1

Options:
  --version          Show help/version info
  --log-level LEVEL  Set the logging level (debug|info|warn|error|fatal)
                     (Default: info)
```

Not to bad for having written two lines of code!  We can also see that `fullstop` will error out if we omit our required
argument, `repo_url`:

```sh
$ bundle exec bin/fullstop 
parse error: 'repo_url' is required

Usage: fullstop [options] repo_url

Manages dotfiles from a git repo

v0.0.1

Options:
  --version          Show help/version info
  --log-level LEVEL  Set the logging level (debug|info|warn|error|fatal)
                     (Default: info)
$ echo $?
64
```

We see an error message, and exited nonzero (64 is a somewhat standard exit code for issues with command-line invocation).

It's also worth pointing out that Methadone is taking a very light touch.  We could completely re-implement `bin/fullstop` using
`OptionParser` and still have our scenario pass.  As we'll see, few of Methadone's parts really rely on each other, and many can
be used peacemeal, if that's what you want.

Now that we have our UI, the next order of business is to actually implement something.
[outsidein]: http://en.wikipedia.org/wiki/Outside%E2%80%93in_software_development
