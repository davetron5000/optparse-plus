# Bootstrapping our app

One thing that's great about writing a webapp with Ruby on Rails is that, with one command, you have a skeleton app, including
a fully functional test framework set up.  You can start writing tests immediately.  There's no common equivalent for a
command-line app, which is what Methadone aims to provide.

Methadone will also bootstrap other aspects of your app, such a `Rakefile`, a gemspec, a shell of an executable, a license, and a
README.  First, let's install Methadone via RubyGems (note that if your aren't using rvm, you may need to use `sudo` to install
gems):

```sh
$ gem install methadone
Fetching: methadone-1.0.0.gem (100%)
Successfully installed methadone-1.0.0
1 gem installed
Installing ri documentation for methadone-1.0.0...
Installing RDoc documentation for methadone-1.0.0...
```

Methadone comes bundled with a command-line app that will do the bootstrapping:

```sh
$ methadone --help
Usage: methadone [options] app_name

Kick the bash habit by bootstrapping your Ruby command-line apps

v1.0.0

Options:
        --force                      Overwrite files if they exist
        --[no-]readme                [Do not ]produce a README file
    -l, --license LICENSE            Specify the license for your project (mit|apache|custom|NONE)
        --log-level LEVEL            Set the logging level (debug|info|warn|error|fatal)
                                     (Default: info)
        --version                    Show help/version info

Default values can be placed in the METHODONE_OPTS environment variable
```

The app that we'll be building in this tutorial is be called `fullstop`, which is derived from the [British name][fullstop] for a period, which is the character used as a prefix to our dotfiles, and, is the reason they are called "dot" files in the first place.  Based on the command-line syntax for `methadone`, we can create our app right now with one simple command.  We'll use the Apache license as well as a README.

[fullstop]: http://en.wikipedia.org/wiki/Full_stop

```sh
$ methadone --readme --license apache fullstop
$ ls fullstop
Gemfile           README.rdoc       bin/              
fullstop.gemspec  test/             LICENSE.txt       
Rakefile          features/         lib/
```

As you can see, we've got a generic gemified project.  Before we can start developing, we'll need to install a few gems using Bundler first:

```sh
$ cd fullstop
$ bundle install
Fetching source index for http://rubygems.org/
Installing rake (0.9.2.2) 
Installing ffi (1.0.11) with native extensions 
Installing childprocess (0.3.1) 
Installing builder (3.0.0) 
Installing diff-lcs (1.1.3) 
Installing json (1.6.5) with native extensions 
Installing gherkin (2.7.6) with native extensions 
Installing term-ansicolor (1.0.7) 
Installing cucumber (1.1.4) 
Installing rspec-core (2.8.0) 
Installing rspec-expectations (2.8.0) 
Installing rspec-mocks (2.8.0) 
Installing rspec (2.8.0) 
Installing aruba (0.4.11) 
Using bundler (1.0.21) 
Installing methadone (0.5.1) 
Using fullstop (0.0.1) from source at /Users/davec/Projects/methadone/tutorial/code/fullstop 
Installing rdoc (3.12) 
Your bundle is complete! Use `bundle show [gemname]` to see where a bundled gem is installed.
```

Your versions might not match up, but this should be more or less what you see.  The first thing you'll notice is that this seems
like a *lot* of gems!  Most of them are brought in by our acceptance testing framework, [aruba][aruba], which is a library on top
of [cucumber][cucumber] tailor-made for testing command-line apps.  Methadone also assumes  you'll be unit
testing with `Test::Unit`, which is a fine default.   In fact, both unit and acceptance tests are set up for you and available
via `rake` tasks.  Let's see them in action.

[aruba]: http://www.github.com/cucumber/aruba
[cucumber]: http://cukes.info

```sh
$ rake
Run options: 

# Running tests:

.

Finished tests in 0.000623s, 1605.1364 tests/s, 1605.1364 assertions/s.

1 tests, 1 assertions, 0 failures, 0 errors, 0 skips
......

1 scenario (1 passed)
6 steps (6 passed)
0m0.136s
```

As you can see, we ran one unit test and one cucumber scenario.  These were provided by Methadone as placeholders for your tests.
Just like what Ruby on Rails does when you create an app, Methadone has reduced the friction between your need to write software
and your ability to do so.

Methadone also generated a very basic scaffold of the command-line app itself.  It's in `bin` and is called `fullstop` (the
argument we gave to `methadone`).  Let's run it now:

```sh
$ bin/fullstop
/Users/davec/.rvm/rubies/ruby-1.9.3-p0/lib/ruby/site_ruby/1.9.1/rubygems/custom_require.rb:36:in `require': cannot load such file -- fullstop (LoadError)
from /Users/davec/.rvm/rubies/ruby-1.9.3-p0/lib/ruby/site_ruby/1.9.1/rubygems/custom_require.rb:36:in `require'
from bin/fullstop:5:in `<main>'
```

Oops!  What happened?  

Methadone is encouraging you to develop your app with best practices, and one such practice is to not have your executables mess with the load path.  In many Ruby command-line applications, you'll see code like this at the top of the file:

```ruby
$: << File.join(File.dirname(__FILE__),'..','lib')
```

This puts the `lib` directory, that is relative to the `bin` directory (where our executable lives), into Ruby's load path.  This will allow *us* to run the app easily, but for your users, it's not necessary if you distribute your app with RubyGems (which you should do) and it's generally not a good idea to modify the load path.  In order to run the app directly during development, we'll need to use `bundle exec`, like so (note that we won't be running our app a lot in development, but scripting it using Aruba so we can test its behavior in an automated way):

```sh
$ bundle exec bin/fullstop --help
Usage: fullstop [options]

v0.0.1

Options:
        --version                    Show help/version info
        --log-level LEVEL            Set the logging level (debug|info|warn|error|fatal)
                                         (Default: info)
```


Not too bad!  We've got the makings of a reasonable help system, versioning support, a usage statement and a working executable.
Just remember to run the app with `bundle exec` while you're developing.  Remember, your users won't have to worry about as long
as they installed it with RubyGems.

Before we move on, let's look at the cucumber scenario that Methadone generated for us.  We're going to work "outside in" on our
app, so this will be a sneak peek at what we'll be doing next.

```sh
$ cat features/fullstop.feature 
```
```cucumber
Feature: My bootstrapped app kinda works
  In order to get going on coding my awesome app
  I want to have aruba and cucumber setup
  So I don't have to do it myself

  Scenario: App just runs
    When I get help for "fullstop"
    Then the exit status should be 0
    And the banner should be present
    And the banner should document that this app takes options
    And the following options should be documented:
      |--version|
    And the banner should document that this app takes no arguments
```

We probably won't keep this exactly scenario around, but it's a good demonstration of Aruba and Cucumber, and will help to get us
going.  Since this scenario passes, that means that we already have the cucumber steps defined somewhere.  As we'll see, the
combination of Aruba and Methadone results in a lot of pre-defined steps that make acceptance testing a snap.

In the next section, we'll expand this scenario to create the user interface we'll need to get our app going.
