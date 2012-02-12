# Refactoring

Refactoring is an important step in TDD, and a Methadone-powered app works just as well with the code all jumbled inside our
executable as it would with things nicely organized in classes.  Since we'll distribute our app with RubyGems, it will all work
out at runtime.

Currently, our `main` block looks like this:

```ruby
main do |repo_url|
  
  Dir.chdir options['checkout-dir'] do
    basedir = repo_url.split(/\//)[-1].gsub(/\.git$/,'')
    if options[:force] && Dir.exists?(basedir)
      warn "deleting #{basedir} before cloning"
      FileUtils.rm_rf basedir
    end
    if sh("git clone #{repo_url}") == 0
      Dir.entries(basedir).each do |file|
        next if file == '.' || file == '..' || file == '.git'
        source_file = File.join(basedir,file)
        FileUtils.rm(file) if File.exists?(file) && options[:force]
        FileUtils.ln_s source_file,'.'
      end
    else
      exit_now!("checkout dir already exists, use --force to overwrite")
    end
  end
end
```

Let's create some methods first to clean up this, and then see if any classes emerge.

```ruby
main do |repo_url|
  Dir.chdir options['checkout-dir'] do
    repo_dir = clone_repo(repo_url,options[:force])
    files_in(repo_dir) do |file|
      link_file(repo_dir,file,options[:force])
    end
  end
end

def self.link_file(repo_dir,file,overwrite)
  source_file = File.join(repo_dir,file)
  FileUtils.rm(file) if File.exists?(file) && overwrite
  FileUtils.ln_s source_file,'.'
end

def self.files_in(repo_dir)
  Dir.entries(repo_dir).each do |file|
    next if file == '.' || file == '..' || file == '.git'
    yield file
  end
end

def self.clone_repo(repo_url,force)
  repo_dir = repo_url.split(/\//)[-1].gsub(/\.git$/,'')
  if force && Dir.exists?(repo_dir)
    warn "deleting #{repo_dir} before cloning"
    FileUtils.rm_rf repo_dir
  end
  unless sh("git clone #{repo_url}") == 0
    exit_now!("checkout dir already exists, use --force to overwrite")
  end
  repo_dir
end
```

Our `main` block is now a lot clearer, and, although we have more code, each routine is much more concise and cohesive.  Let's
run our features to make sure nothing's broken.  

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
0m1.277s
```

Everything's still working, so our refactor was good.  We'd like to move a lot of the code out of our executable.  This will let
us unit test it better, and generally make things a bit easier to organize and understand.  The objects of our app are
"Repositories" and "Files".  Ruby already has a `File` class, so let's start with "Repository".  We'll make one in `lib` that can
be cloned and whose files can be listed.

We'll create a class named `Repo` in `lib/fullstop/repo.rb` that has a factory method, `clone_from`, that will clone and create a
`Repo` instance that has a method `repo_dir` exposing the dir where the repo was cloned, and `files` which iterates over each
file in the repo, skipping '.' and '..' as before:

```ruby
module Fullstop
  class Repo

    include Methadone::CLILogging
    include Methadone::SH
    include Methadone::Main

    def self.clone_from(repo_url,force=false)
      repo_dir = repo_url.split(/\//)[-1].gsub(/\.git$/,'')
      if force && Dir.exists?(repo_dir)
        warn "deleting #{repo_dir} before cloning"
        FileUtils.rm_rf repo_dir
      end
      unless sh("git clone #{repo_url}") == 0
        exit_now!("checkout dir already exists, use --force to overwrite")
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
        yield file
      end
    end
  end
end
```

We'll explain why we included the Methadone modules a bit later.  Now, our `bin/fullstop` executable now looks like so:

```ruby
#!/usr/bin/env ruby

require 'optparse'
require 'methadone'
require 'fullstop'
require 'fileutils'

class App
  include Methadone::ExitNow
  include Methadone::CLILogging
  include Methadone::SH
  include Fullstop

  main do |repo_url|
    Dir.chdir options['checkout-dir'] do
      repo = Repo.clone_from(repo_url,options[:force])
      repo.files do |file|
        link_file(repo,file,options[:force])
      end
    end
  end

  def self.link_file(repo,file,overwrite)
    source_file = File.join(repo.repo_dir,file)
    FileUtils.rm(file) if File.exists?(file) && overwrite
    FileUtils.ln_s source_file,'.'
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

It's now a lot shorter, easier to understand and we have our code in classes, where they can be tested in a fast-running unit
test.

The point of all this is that *none of this matters to Methadone*.  When you distribute your app, the code will be available, and
thus you can organize it however you'd like.

You've noticed that we've been punting on a few things that we've seen, most recently, the module `Methadone::CLILogging`.  At
this point, you know enough to effectively use Methadone to make awesome command-line apps.  In the next section, we'll take a
closer look at how logging and debugging work with a Methadone app.
