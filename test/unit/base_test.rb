require "minitest/autorun"
require "rspec/expectations"
require "ostruct"
require_relative "clean_test_inlined"

RSpec::Matchers.configuration.syntax = :should

class BaseTest < Minitest::Test
  include RSpec::Matchers
  include CleanTestInlined
end
