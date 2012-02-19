# Logging & Debugging

By now, you've got the basics of using Methadone, but there's a few things happening under the covers that you should know about,
and a few things built-in to the methods and modules we've been using that will be helpful both in developing your app and in
examining its behavior in production.

When trying to figure out what's going on with our apps, be it in development or producton, we often first turn to `puts`
statements, like so:

```ruby
if sh "rsync /apps/my_app/ backup-srv:/apps/my_app" == 0
  puts "rsync successful"
  # do other things
else
  puts "Something, went wrong: #{$!}"
end
```

Because of the way `system` or the backtick operator work, this sort of debugging isn't terribly helpful.  It's also hard to turn
off: you either delete the lines (possibly adding them back later when things go wrong again), or comment them out, which 
leads to hard-to-follow code and potentially misleading messages.

Instead, you should use logging, and Methadone bakes logging right in.

## Logging

We've seen the module `Methadone::CLILogging` before.  This module can be mixed into any class and does two things:

* Provides a shared instance of a logger, available via the method `logger`
* Provides the convienience methods `debug`, `info`, `warn`, `error`, and `fatal`, which proxy to the underlying logger.

In a Methadone app, most output should be done using the logger.  The above code would look like so:

```ruby
if sh "rsync /apps/my_app/ backup-srv:/apps/my_app" == 0
  debug "rsync successful"
  # do other things
else
  warn "Something, went wrong: #{$!}"
end
```

At runtime, you can change the log level, meaning you can hide the `debug` statement without changing your code.  You may have
noticed in our tutorial app, `fullstop`, that the flag `--log-level` was shown as an option.  The method `use_log_level_option`
enables this flag.  This means that you don't have to do *anything additional* to get full control over your logging.

Methadone goes beyond this, however, and makes heavy use of the logger in the `Methadone::SH` module.  This module assumes that
`Methadone::CLILogging` is mixed in (or, more specifically, assumes a method `logger` which returns a `Logger`), and all
interaction with external commands via `sh` is logged in a useful and appropriate manner.

By default, `sh` will log the full command it executes at debug level.  It will also capture the standard output and standard error of the commands you run and examine the exit code.

Any output to the standard error device is logged as a warning; error output from commands you call is important and should be
examined.  

If the exit code of the command is zero, the standard output is logged at debug level, otherwise it will be logged at info level.

What this means is that you can dial up logging to debug level in production to see everything your app is doing, but can
generally keep the log level higher, to reduce log noise.  This is a powerful tool for debugging your apps, and it doesn't
require any code changes.

Let's enhance `bin/fullstop` to log more things, and examine what's going on.  First, we'll add an info message to our executable
that indicates that everything worked. Generally, you don't want to add noisy messages like this (see [my book][clibook] for a
deeper discussion as to why), however for demonstration purposes, it should be OK.  Here's just the `main` block with our
additional logging:

```ruby
main do |repo_url|
  Dir.chdir options['checkout-dir'] do
    repo = Repo.clone_from(repo_url,options[:force])
    repo.files do |file|
      link_file(repo,file,options[:force])
    end
  end
  # vvv
  info "Dotfiles symlinked"
  # ^^^
end
```

We'll also add some debug logging to `Repo`.  This can be useful since we're doing some filename manipulation with regular
expressions and it might help to see what's going on if we encouter an odd bug:

```ruby
module Fullstop
  class Repo

    include Methadone::CLILogging
    include Methadone::SH
    include Methadone::ExitNow

    def self.clone_from(repo_url,force=false)
      repo_dir = repo_url.split(/\//)[-1].gsub(/\.git$/,'')
      # vvv
      debug "Cloning #{repo_url} into #{repo_dir}"
      # ^^^
      if force && Dir.exists?(repo_dir)
        warn "deleting #{repo_dir} before cloning"
        FileUtils.rm_rf repo_dir
      end
      if sh("git clone #{repo_url}") == 0
        exit_now!(1,"checkout dir already exists, use --force to overwrite")
      end
      Repo.new(repo_dir)
    end

    attr_reader :repo_dir
    def initialize(repo_dir)
      @repo_dir = repo_dir
    end

    def files
      Dir.entries(@repo_dir).each do |file|
        next if file == '.' || file == '..' || file == '.git'
        # vvv
        debug "Yielding #{file}"
        # ^^^
        yield file
      end
    end
  end
end
```

Let's run our app on the command-line:

```sh
$ HOME=/tmp/fake-home bundle exec bin/fullstop file:///tmp/dotfiles.git
Dotfiles symlinked
```

As we can see, things went normally and we saw just our info message.  By default, the Methadone logger is set at info level.
Let's try it again at debug level:

```sh
$ rm -rf /tmp/fake-home ; mkdir /tmp/fake-home/
$ HOME=/tmp/fake-home bundle exec bin/fullstop --log-level=debug file:///tmp/dotfiles.git
Cloning file:///tmp/dotfiles.git into dotfiles
Executing 'git clone file:///tmp/dotfiles.git'
Output of 'git clone file:///tmp/dotfiles.git': Cloning into dotfiles...
Yielding .bashrc
Yielding .exrc
Yielding .inputrc
Yielding .vimrc
Dotfiles symlinked
```

As you can see, we see all the debug messages.  Now, let's redirect that to a log file and see what it looks like.

```sh
$ rm -rf /tmp/fake-home ; mkdir /tmp/fake-home/
$ HOME=/tmp/fake-home bundle exec bin/fullstop --log-level=debug file:///tmp/dotfiles.git > fullstop.log
$ cat fullstop.log 
D, [2012-02-13T21:11:05.924220 #49986] DEBUG -- : Cloning file:///tmp/dotfiles.git into dotfiles
D, [2012-02-13T21:11:05.928311 #49986] DEBUG -- : Executing 'git clone file:///tmp/dotfiles.git'
D, [2012-02-13T21:11:05.950333 #49986] DEBUG -- : Output of 'git clone file:///tmp/dotfiles.git': Cloning into dotfiles...
D, [2012-02-13T21:11:05.950566 #49986] DEBUG -- : Yielding .bashrc
D, [2012-02-13T21:11:05.950752 #49986] DEBUG -- : Yielding .exrc
D, [2012-02-13T21:11:05.950866 #49986] DEBUG -- : Yielding .inputrc
D, [2012-02-13T21:11:05.950968 #49986] DEBUG -- : Yielding .vimrc
I, [2012-02-13T21:11:05.951086 #49986]  INFO -- : Dotfiles symlinked
```
The format has changed.  Methadone reasons that if you are showing output to a terminal TTY, the user will not need or want to
see the logging level of each message nor the timestamp.  However, if the user has redirected the output to a file, this
information becomes much more useful.

Now, let's run the app again, but without "resetting" our fake home directory in `/tmp/fake-home`.

```sh
$ HOME=/tmp/fake-home bundle exec bin/fullstop file:///tmp/dotfiles.git
Error output of 'git clone file:///tmp/dotfiles.git': fatal: destination path 'dotfiles' already exists and is not an empty directory.
Output of 'git clone file:///tmp/dotfiles.git': 
Error running 'git clone file:///tmp/dotfiles.git'
checkout dir already exists, use --force to overwrite
```

We get several error messages.  Let's redirect the standard output to a file and try again.

```ruby
$ HOME=/tmp/fake-home bundle exec bin/fullstop file:///tmp/dotfiles.git > fullstop.log 
Error output of 'git clone file:///tmp/dotfiles.git': fatal: destination path 'dotfiles' already exists and is not an empty directory.
Error running 'git clone file:///tmp/dotfiles.git'
checkout dir already exists, use --force to overwrite
$ cat fullstop.log 
W, [2012-02-13T21:13:29.819867 #50061]  WARN -- : Error output of 'git clone file:///tmp/dotfiles.git': fatal: destination path 'dotfiles' already exists and is not an empty directory.
I, [2012-02-13T21:13:29.820076 #50061]  INFO -- : Output of 'git clone file:///tmp/dotfiles.git': 
W, [2012-02-13T21:13:29.820120 #50061]  WARN -- : Error running 'git clone file:///tmp/dotfiles.git'
E, [2012-02-13T21:13:29.820251 #50061] ERROR -- : checkout dir already exists, use --force to overwrite
```

As you can see, our terminal (which is only showing the standard error output) shows us only the warning and log messages, and
ourlog file has *all* the messages.  This gives you a *lot* of flexibility.  

The normal Ruby `Logger` doesn't have quite these smarts; it produces messages onto one `IO` device.  Methadone is sending
messages to potentially many places.  How does this work?

## Methadone's Special Logger

The logger used by default in `Methadone::CLILogging` is a `Methadone::CLILogger`.  This
is a special logger designed for command-line apps.  By default, any message logged at warn or higher will go to the standard
error stream.  Messages logged at info and debug will go to the standard output stream.  This allows you to fluently communicate
things to the user and have them go to the appropriate place.

Further, when your app is run at a terminal, these messages are unformatted.   When your apps output is redirected somewhere, the
messages are formatted with date and time stamps, as you'd expect in a log.

Note that if you want a normal Ruby logger (or want to use the Rails logger in a Rails environment), you can still get the
benefits of `Methadone::CLILogging` without being required to use the `Methadone::CLILogger`.  I've used this to great affect to
use the thread-safe [Log4r][log4r] logger in a JRuby app.  Let's change `bin/fullstop` to use a plain Ruby Logger instead of
Methadone's fancy logger.

We just need to change one line in `bin/fullstop`, to call `change_logger` inside our `main` block:

```ruby
main do |repo_url|
  # vvv
  change_logger(Logger.new(STDERR))
  # ^^^
  Dir.chdir options['checkout-dir'] do
    repo = Repo.clone_from(repo_url,options[:force])
    repo.files do |file|
      link_file(repo,file,options[:force])
    end
  end
  info "Dotfiles symlinked"
end
```

All other files stay as they are.  Now, let's re-run our app, first cleaning up the fake home directory, and then immediately
running the app again to see errors.

```sh
$ rm -rf /tmp/fake-home ; mkdir /tmp/fake-home/
$ HOME=/tmp/fake-home bundle exec bin/fullstop --log-level=debug file:///tmp/dotfiles.git > fullstop.log
D, [2012-02-13T21:18:11.492004 #50317] DEBUG -- : Cloning file:///tmp/dotfiles.git into dotfiles
D, [2012-02-13T21:18:11.492125 #50317] DEBUG -- : Executing 'git clone file:///tmp/dotfiles.git'
D, [2012-02-13T21:18:11.513846 #50317] DEBUG -- : Output of 'git clone file:///tmp/dotfiles.git': Cloning into dotfiles...
D, [2012-02-13T21:18:11.514113 #50317] DEBUG -- : Yielding .bashrc
D, [2012-02-13T21:18:11.514339 #50317] DEBUG -- : Yielding .exrc
D, [2012-02-13T21:18:11.514516 #50317] DEBUG -- : Yielding .inputrc
D, [2012-02-13T21:18:11.514719 #50317] DEBUG -- : Yielding .vimrc
I, [2012-02-13T21:18:11.514899 #50317]  INFO -- : Dotfiles symlinked
HOME=/tmp/fake-home bundle exec bin/fullstop --log-level=debug file:///tmp/dotfiles.git > fullstop.log
D, [2012-02-13T21:18:17.181995 #50348] DEBUG -- : Cloning file:///tmp/dotfiles.git into dotfiles
D, [2012-02-13T21:18:17.182112 #50348] DEBUG -- : Executing 'git clone file:///tmp/dotfiles.git'
W, [2012-02-13T21:18:17.186447 #50348]  WARN -- : Error output of 'git clone file:///tmp/dotfiles.git': fatal: destination path 'dotfiles' already exists and is not an empty directory.
I, [2012-02-13T21:18:17.186579 #50348]  INFO -- : Output of 'git clone file:///tmp/dotfiles.git': 
W, [2012-02-13T21:18:17.186621 #50348]  WARN -- : Error running 'git clone file:///tmp/dotfiles.git'
E, [2012-02-13T21:18:17.186798 #50348] ERROR -- : checkout dir already exists, use --force to overwrite
```

As you can see, our output is the default for a Ruby `Logger`, and there's no special formatting.  You'll also notice that, even
though we redirected standard out to a log, we still saw all the messages.  Since our `Logger` was configured to use the standard
error stream, our terminal gets all the messages.

Note that all of our code, include code in `lib/fullstop/repo.rb` uses this logger via the convienience methods provided by
`Methadone::CLILogging`.  This is a great way to avoid global variables, and can provide central control over your logging and
output.

## Exceptions

We've already seen the use of `exit_now!` to abort our app and show the user an error message.  `exit_now!` is implemented to
raise a `Methadone::Error`, but we could've just as easily raised a `StandardError` or `RuntimeError` ourselves.  The result
would be the same: Methadone would show the user just the error message and exit nonzero.

Methadone traps all exceptions, so that users never see a backtrace.  Generally, this is what you want, because it allows you to
write your code without complex exit logic and you don't need to worry about a bad user experience by letting stack traces leak
through to the output.  In fact, the method `go!` that we've seen at the bottom of our executables handles this.

There are times, however, when you want to see these traces.  When writing and debugging your app, the exception backtraces are
crucial for identifying where things went wrong.

All Methadone apps look for the environment variable `DEBUG` and, if it's set to "true", will show the stack trace on errors
instead of hiding it.  Let's see it work with `bin/fullstop`.  We've restored it back to use a `Methadone::CLILogger`, and we can now see how `DEBUG` affects the output:

```sh
$ HOME=/tmp/fake-home bundle exec bin/fullstop --log-level=debug file:///tmp/dotfiles.git
Cloning file:///tmp/dotfiles.git into dotfiles
Executing 'git clone file:///tmp/dotfiles.git'
Error output of 'git clone file:///tmp/dotfiles.git': fatal: destination path 'dotfiles' already exists and is not an empty directory.
Output of 'git clone file:///tmp/dotfiles.git': 
Error running 'git clone file:///tmp/dotfiles.git'
checkout dir already exists, use --force to overwrite
$ DEBUG=true HOME=/tmp/fake-home bundle exec bin/fullstop --log-level=debug file:///tmp/dotfiles.git
Cloning file:///tmp/dotfiles.git into dotfiles
Executing 'git clone file:///tmp/dotfiles.git'
Error output of 'git clone file:///tmp/dotfiles.git': fatal: destination path 'dotfiles' already exists and is not an empty directory.
Output of 'git clone file:///tmp/dotfiles.git': 
Error running 'git clone file:///tmp/dotfiles.git'
/Users/davec/.rvm/gems/ruby-1.9.3-p0@methadone-tutorial/gems/methadone-1.0.0.rc2/lib/methadone/exit_now.rb:21:in `exit_now!': checkout dir already exists, use --force to overwrite (Methadone::Error)
	from /Users/davec/Projects/methadone/tutorial/code/fullstop/lib/fullstop/repo.rb:18:in `clone_from'
	from bin/fullstop:16:in `block (2 levels) in <class:App>'
	from bin/fullstop:15:in `chdir'
	from bin/fullstop:15:in `block in <class:App>'
	from /Users/davec/.rvm/gems/ruby-1.9.3-p0@methadone-tutorial/gems/methadone-1.0.0.rc2/lib/methadone/main.rb:273:in `call'
	from /Users/davec/.rvm/gems/ruby-1.9.3-p0@methadone-tutorial/gems/methadone-1.0.0.rc2/lib/methadone/main.rb:273:in `call_main'
	from /Users/davec/.rvm/gems/ruby-1.9.3-p0@methadone-tutorial/gems/methadone-1.0.0.rc2/lib/methadone/main.rb:147:in `go!'
	from bin/fullstop:42:in `<class:App>'
	from bin/fullstop:8:in `<main>'
```

Occasionally, you might *always* want the exceptions to leak through.  For example, if your app is being run as part of some
other system that you don't have precise control over, such as [monit][monit], the backtrace will tell you what went wrong if the
system can't properly start your app.  In this case, use the method `leak_exceptions` to permanently show the backtrace.  Note that this method will only leak exceptions that *aren't* of type `Methadone::Error`.
