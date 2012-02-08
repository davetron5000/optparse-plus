# Awesome Ruby Command Line Apps with Methadone

Kick the bash habit, and make all your command-line apps with Ruby.  

In [Build Awesome Command-Line Applications in Ruby][clibook], I lay out how to make an awesome command-line application using
Ruby.  The book focuses on tools like `OptionParser` to create the app.  As I wrote and researched, it became clear that there
was a gap between `OptionParser`, which is very powerful, yet verbose, and other command line tools like [trollop][trollop], 
[main][main], and [thor][thor], which have simple APIs, but aren't very powerful.  

I created Methadone to bridge that gap.  Methadone provides all the power of `OptionParser`, but has a simple, clean API.
Methadone also includes additional tools and classes to make your command-line apps even better.

This tutorial will show you how to make a simple command-line app using Methadone that will be easy-to-use, easy-to-maintain, and
fully tested.

## What you'll need

You'll need an installation of Ruby and the ability to install Ruby gems.  I would recommend that you use rvm and a gemset to
work through these, but they aren't required.  Although Methadone works on most versions of Ruby, I would recommend you use Ruby
1.9.3, if you can.  If not, try to use an MRI Ruby as those versions (1.8.7, REE, 1.9.2, or 1.9.3) have the highest compatibility
with other gems.

## How this is organized

This is a tutorial for making a simple command-line app.  Unlike some tutorials and books, we will be working through this using
a "test-first" approach.  One thing that Methadone tries to enable is using [TDD][tdd] for creating and writing your command-line
app.  As such, we'll write tests as much as possible to drive our work.

## The tutorial app

The app we'll build is going to manage "dot files".  These are the files that live in your home directory and configure your
shell, editor, and various other programs.  For example, `~/.bashrc` is the file to configure `bash`.  Many developers keep these
files on [Github][github] so that they can maintain the same files across multiple computers.

To set this up on a new computer, you have to checkout the repo, and symlink all the files to your home directory.  To update the
files you have to update the repo and then check if any new files were added.  This is the sort of tedious manual process that is
ripe for automation via a command-line app.

We'll develop a simplified version to demonstrate how to use Methadone.

