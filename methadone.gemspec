# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "methadone/version"

Gem::Specification.new do |s|
  s.name        = "methadone"
  s.version     = Methadone::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["davetron5000"]
  s.email       = ["davetron5000 at gmail.com"]
  s.homepage    = "http://github.com/davetron5000/methadone"
  s.summary     = %q{Kick the bash habit and start your command-line apps off right}
  s.description = %q{Methadone provides a lot of small but useful features for developing a command-line app, including an opinionated bootstrapping process, some helpful cucumber steps, and some classes to bridge logging and output into a simple, unified, interface}

  s.rubyforge_project = "methadone"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_dependency("bundler")
  s.add_development_dependency("rspec-expectations", "~> 2.6")
  s.add_development_dependency("rake")
  s.add_development_dependency("rdoc","~> 3.9")
  s.add_development_dependency("cucumber","~> 1.1.1")
  s.add_development_dependency("aruba")
  s.add_development_dependency("simplecov", "~> 0.5")
  s.add_development_dependency("clean_test", "~> 0.10")
  s.add_development_dependency("mocha")
end
