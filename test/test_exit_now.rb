require 'base_test'
require 'methadone'
require 'stringio'

class TestExitNow < BaseTest
  include Methadone
  include Methadone::ExitNow

  test_that "exit_now raises the proper error" do
    Given {
      @exit_code = any_int :min => 1
      @message = any_string
    }
    When {
      @code = lambda { exit_now!(@exit_code,@message) }
    }
    Then {
      exception = assert_raises(Methadone::Error,&@code)
      exception.exit_code.should == @exit_code
      exception.message.should == @message
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
      exception = assert_raises(Methadone::Error,&@code)
      exception.exit_code.should == 1
      exception.message.should == @message
    }
  end
end 
