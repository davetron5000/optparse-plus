require 'base_test'
require 'optparse_plus'
require 'stringio'

class TestExitNow < BaseTest
  include OptparsePlus
  include OptparsePlus::ExitNow

  test_that "exit_now raises the proper error" do
    Given {
      @exit_code = rand(99) + 1
      @message = any_string
    }
    When {
      @code = lambda { exit_now!(@exit_code,@message) }
    }
    Then {
      exception = assert_raises(OptparsePlus::Error,&@code)
      exception.exit_code.should be == @exit_code
      exception.message.should be == @message
    }
  end

  test_that "exit_now without an exit code uses 1 as the exti code" do
    Given {
      @message = any_string
    }
    When {
      @code = lambda { exit_now!(@message) }
    }
    Then {
      exception = assert_raises(OptparsePlus::Error,&@code)
      exception.exit_code.should be == 1
      exception.message.should be == @message
    }
  end
end 
