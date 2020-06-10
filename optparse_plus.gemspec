# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "optparse_plus/version"

Gem::Specification.new do |s|
  s.name        = "optparse-plus"
  s.version     = OptparsePlus::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["davetron5000"]
  s.email       = ["davetron5000 at gmail.com"]
  s.homepage    = "http://github.com/davetron5000/optparse-plus"
  s.summary     = %q{Wrapper around the Standard Library's Option Parser to make CLIs Easier}
  s.description = %q{OptparsePlus provides a lot of small but useful features for developing a command-line app, including an opinionated bootstrapping process, some helpful integration test support, and some classes to bridge logging and output into a simple, unified, interface}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_dependency("bundler")
  s.add_development_dependency("rake")
  s.add_development_dependency("rdoc","~> 6.0")
  s.add_development_dependency("sdoc")
  s.add_development_dependency("simplecov", "~> 0.5")
  s.add_development_dependency("clean_test", "~> 1.0.1")
  s.add_development_dependency("mocha")
  s.add_development_dependency("rspec") # needed for testing the generated tests
  s.add_development_dependency("i18n")
end
