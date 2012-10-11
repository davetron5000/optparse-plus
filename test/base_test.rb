require 'simplecov'
SimpleCov.start do
  add_filter "/test"
end
require 'test/unit'
require 'rspec/expectations'
require 'clean_test/test_case'
require 'ostruct'

class BaseTest < Clean::Test::TestCase
end
