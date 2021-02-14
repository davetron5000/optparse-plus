require "base_test"
require "mocha/minitest"
require "optparse_plus"

# Define this symbol without requiring the library;
# all we're going to do is mock calls to it
module Open4
end

module ExecutionStrategy
  class TestRBXOpen_4 < BaseTest
    include OptparsePlus::ExecutionStrategy

    test_that "exception_meaning_command_not_found returns Errno::EINVAL" do
      Given {
        @strategy = RBXOpen_4.new
      }
      When {
        @klass = @strategy.exception_meaning_command_not_found
      }
      Then {
        @klass.should == [Errno::EINVAL,Errno::ENOENT]
      }
    end
  end
end
