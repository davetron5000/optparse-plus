# Changelog

## Upcoming Version

* Can create an app with a dash in its name (See [55])
* Help switches, `-h`, and `--help` are documented in help output (See [51])
* Improve cucumber step requiring docs and fix bug where said docs had to start with a three-letter words (See [37])

[37]: http://github.com/davetron5000/methadone/issues/37
[51]: http://github.com/davetron5000/methadone/issues/51
[55]: http://github.com/davetron5000/methadone/issues/55

## v1.2.3 - Oct 21, 2012

* Generated Rakefile has better formatted code (See [57])
* Error output preface now says "stderr is" instead of "error output", which is less confusing (See [53])

[57]: http://github.com/davetron5000/methadone/issues/57
[53]: http://github.com/davetron5000/methadone/issues/53

## v1.2.2 - Oct 2, 2012

* Less scary stdout/stderr prefixing from SH, courtesy @yoni

## v1.2.1 - Jun 10, 2012, 3:41 PM

* Slightly loosen what passes for a one-line description of the app, courtesy @jredville

## v1.2.0 - May 21, 2012, 11:05 PM

* Better handling of `open4` dependency when you don't install it and you don't use it.
* Quoted spaced strings in config files and env var weren't working.  Now they are.
* Use the current version in generated gemspec
* Non-string arguments (such as Regexps for validation and classes for type conversion) were not working.  Now they are.
* `sh` can now be used more safely by passing an array to avoid tokenization (thanks @gchpaco!)

## v1.1.0 - April 21, 2012, 6:00 PM

* Can bootstrap apps using RSpec instead of Test::Unit (thanks @msgehard)

## v1.0.0 - April 1, 2012, 10:31

* Initial official release
