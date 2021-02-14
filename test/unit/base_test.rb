require 'test/unit'
require 'rspec/expectations'
require 'clean_test/test_case'
require 'ostruct'

RSpec::Matchers.configuration.syntax = :should

class BaseTest < Clean::Test::TestCase
  include RSpec::Matchers
end
