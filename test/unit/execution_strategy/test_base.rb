require 'base_test'

module ExecutionStrategy
  class TestBase < BaseTest
    include OptparsePlus::ExecutionStrategy

    [
      [:run_command,["ls"]],
      [:exception_meaning_command_not_found,[]],
    ].each do |(method,args)|
      test_that "#{method} isn't implemented" do
        Given {
          @strategy = Base.new
        }
        When {
          @code = lambda { @strategy.send(method,*args) }
        }
        Then {
          assert_raises(RuntimeError,&@code)
        }
      end
    end
  end
end
