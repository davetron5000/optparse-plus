# Tutorial: UI

We're taking an [outside-in][outsidein] approach to our app.  This means that we start with the user interface, and work our way
down to make that interface a reality.  I highly recommend this approach, since it forces you to focus on the user of your app
first.   Doing this will result in an app that's easier to use, and thus easier for you to maintain and enhance over time.

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

It's worth understanding why we don't just make this entire thing a `bash` script.  Our app is going to need more smarts than the
above code: for example, it will need to be able to check if the repo is cloned already, and update it instead of cloning.  It
will need good error handling so the user knows if they did something wrong.  It might need more complex logic as we use the app
over time.  Implementing these in `bash` is painful.  `bash` is not a very powerful language, and we'll quickly hit a wall.
Although `bash` is "close to the metal", we'll see that Ruby + Methadone can provide a *very* similar programming experience.

Now, let's think about how our app will work.  We can summarize our app's interface as having two main features at this point:

* It should accept a required argument that is the URL of the repo to clone
* It should otherwise be a well-behaved and polished command-line app:
  * It should have online help.
  * Getting help is not an error and the app should exit zero when you get help.
  * There should be a usage statement for the app's invocation syntax.
  * The app should document what it does.
  * The app should indicate what options and arguments it takes.

Aruba and Methadone provide all the steps we need to test for these aspects of our app's user interface.  Here's the feature
we'll use to test this.  We can replace the contents of `features/fullstop.feature` with this:

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

This scenario describes getting help for our app and the basic user interface that we need.  This is how we "test-drive" the
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

We have a failing test!  Note that cucumber knows about all of these steps; between Aruba and Metahdone, they are all already defined.  We'll see some custom steps later, that are specific to our app, but for now, we haven't had to write any testing code, which is great!
  
You'll also notice that some steps are already passing, despite the fact that we've done no coding.  Also notice that cucumber didn't complain about unknown steps.  Methadone provides almost all of these cucumber steps for us.  The rest are provided by Aruba.  Since Methadone generated an executable for us when we ran the `methadone` command, it already provides the ability to get help, and exits with the correct exit status.

Let's fix things one step at a time, so we can see exactly what we need to do.  The current scenario is failing because our app doesn't have a one line summary.  This summary is important so that we can remember what the app does later on (despite how clever our name is, it's likely we'll forget a few months from now and the description will jog our memory).

Let's have a look at our executable.  A Methadone app is made up of four parts: the setup where we require necessary libraries, a "main" block containing the primary logic of our code, a block of code that declares the app's UI, and a call to `go!`, which runs our app.

```ruby
#!/usr/bin/env ruby

# setup
require 'optparse'
require 'methadone'
require 'fullstop'

class App
  include Methadone::Main
  include Methadone::CLILogging

# the main block
  main do

  end

# declare UI
  version Fullstop::VERSION

  use_log_level_option

# call go!
  go!
end
```

There's not much magic going on here; you could think of this code as being roughly equivalent to:

```ruby
def main
end

opts = OptionParser.new
opts.banner = "usage: $0 [options]\n\nversion: #{Fullstop::VERSION}"
opts.parse!

main
```

We'll see later that Methadone does a lot more than this, but this should help you understand the control flow.  We now need to
add a one-line description for our app.

In a vanilla Ruby application, we'd use the `banner` method of an `OptionParser` to add this description (much as we do with the
version in the above, non-Methadone code).  Methadone actually manages an
`OptionParser` instance that we can use, available via the `opts` method.  We could call `banner` on that to set our description, but Methadone provides a convenience method to do it for us: `description`.

`description` takes a single argument: a one-line description of our app.  Methadone will then include this in the online help 
output of our app when the user uses `-h` or `--help`.  We'll add a call to it in the "declare UI" portion of our code:

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

We got farther this time.  Our step for checking that we have a one-line summary is passing.  Further, the next two following steps are also passing, despite the fact that we did nothing to explicitly make them pass.  Like the preceding steps ("Then the exit status should be 0" and "And the banner should be present"), the two steps following the one we just fixed pass because Methadone has bootstrapped our app in a way that they are already passing.  

The call to Methadone's `version` method ensures that the version of our app appears in the online help.  The other step, "And the banner should document that this app takes options" passes because we are allowing Methadone to manage the banner.  Methadone knows that our app takes options (namely `--version`), and inserts the string `"[options]"` into the usage statement.

The last step in our scenario is still failing, so let's fix that to finish up our user interface.  What Methadone is looking for is for the string `repo_url` (the name of our only, required, argument) to be in the usage string, in other words, Methadone is expecting to see this:

```
Usage: fullstop [option] repo_url
```

Right now, our app's usage string looks like this:

```
Usage: fullstop [option]
```

Again, if we were using `OptionParser`, we would need to modify the argument given to `banner` to include this string.  Methadone provides a method, `arg` that will do this automatically for us.  We'll add it right after the call to `description` in the "declare UI" section of our app:

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
  arg :repo_url, "URL to the git repository containing your dotfiles"
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

Nice!  If our UI should ever change, we'll notice the regression, and we also have an easy way to use TDD to enhance our
application's UI in the future.  Let's take a look at it ourselves to see what it's like:

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

We see an error message, and exited nonzero (64 is a somewhat standard exit code for errors in command-line invocation).

It's also worth pointing out that Methadone is taking a very light touch.  We could completely re-implement `bin/fullstop` using `OptionParser` and still have our scenario pass.  As we'll see, few of Methadone's parts really rely on each other, and many can be used piecemeal, if that's what you want.

Now that we have our UI, the next order of business is to actually implement something.

[outsidein]: http://en.wikipedia.org/wiki/Outside%E2%80%93in_software_development
