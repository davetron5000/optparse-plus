if RUBY_PLATFORM == 'java'
  puts "Simplecov seems to cause JRuby to barf, so use another ruby if you want to check coverage"
else
  require 'simplecov'
  SimpleCov.start do
    add_filter "/test"
  end
end

require 'test/unit'
require 'rspec/expectations'
require 'clean_test/test_case'
require 'ostruct'

RSpec::Matchers.configuration.syntax = :should

class BaseTest < Clean::Test::TestCase
  include RSpec::Matchers
end
