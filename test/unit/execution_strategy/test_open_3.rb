require 'base_test'
require 'mocha/test_unit'
require 'open3'

module ExecutionStrategy
  class TestOpen_3 < BaseTest
    include OptparsePlus::ExecutionStrategy

    test_that "run_command proxies to Open3.capture3" do
      Given {
        @command = any_string
        @stdout = any_string
        @stderr = any_string
        @status = stub('Process::Status')
      }
      When the_test_runs
      Then {
        Open3.expects(:capture3).with(@command).returns([@stdout,@stderr,@status])
      }

      Given new_open_3_strategy
      When {
        @results = @strategy.run_command(@command)
      }
      Then {
        @results[0].should be == @stdout
        @results[1].should be == @stderr
        @results[2].should be @status
      }
    end

    test_that "run_command handles array arguments properly" do
      Given {
        @command = [any_string, any_string, any_string]
        @stdout = any_string
        @stderr = any_string
        @status = stub('Process::Status')
      }
      When the_test_runs
      Then {
        Open3.expects(:capture3).with(*@command).returns([@stdout,@stderr,@status])
      }

      Given new_open_3_strategy
      When {
        @results = @strategy.run_command(@command)
      }
      Then {
        @results[0].should be == @stdout
        @results[1].should be == @stderr
        @results[2].should be @status
      }
    end

    test_that "exception_meaning_command_not_found returns Errno::ENOENT" do
      Given new_open_3_strategy
      When {
        @klass = @strategy.exception_meaning_command_not_found
      }
      Then {
        @klass.should be == Errno::ENOENT
      }
    end

  private
    def new_open_3_strategy
      lambda { @strategy = Open_3.new }
    end
  end
end
