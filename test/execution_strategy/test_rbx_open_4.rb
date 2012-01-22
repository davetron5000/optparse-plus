require 'base_test'
require 'mocha'

# Define this symbol without requiring the library;
# all we're goingn to do is mock calls to it
module Open4
end

module ExecutionStrategy
  class TestRBXOpen_4 < BaseTest
    include Methadone::ExecutionStrategy

    test_that "exception_meaning_command_not_found returns Errno::EINVAL" do
      Given {
        @strategy = RBXOpen_4.new
      }
      When {
        @klass = @strategy.exception_meaning_command_not_found
      }
      Then {
        @klass.should == Errno::EINVAL
      }
    end
  end
end
