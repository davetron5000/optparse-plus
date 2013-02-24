require 'base_test'
require 'mocha/setup'

# Define this symbol without requiring the library;
# all we're goingn to do is mock calls to it
module Open4
end

module ExecutionStrategy
  class TestOpen_4 < BaseTest
    include Methadone::ExecutionStrategy

    test_that "run_command proxies to Open4.capture4" do
      Given {
        @command = any_string
        @stdin_io = mock("IO")
        @stdout = any_string
        @stdout_io = StringIO.new(@stdout)
        @stderr = any_string
        @stderr_io = StringIO.new(@stderr)
        @pid = any_int :min => 2, :max => 65536
        @status = stub('Process::Status')
      }
      When the_test_runs
      Then {
        Open4.expects(:popen4).with(@command).returns([@pid,@stdin_io,@stdout_io,@stderr_io])
        @stdin_io.expects(:close)
        Process.expects(:waitpid2).with(@pid).returns([any_string,@status])
      }

      Given new_open_4_strategy
      When {
        @results = @strategy.run_command(@command)
      }
      Then {
        @results[0].should == @stdout
        @results[1].should == @stderr
        @results[2].should be @status
      }
    end

    test_that "run_command handles array arguments properly" do
      Given {
        @command = [any_string, any_string, any_string]
        @stdin_io = mock("IO")
        @stdout = any_string
        @stdout_io = StringIO.new(@stdout)
        @stderr = any_string
        @stderr_io = StringIO.new(@stderr)
        @pid = any_int :min => 2, :max => 65536
        @status = stub('Process::Status')
      }
      When the_test_runs
      Then {
        Open4.expects(:popen4).with(*@command).returns([@pid,@stdin_io,@stdout_io,@stderr_io])
        @stdin_io.expects(:close)
        Process.expects(:waitpid2).with(@pid).returns([any_string,@status])
      }

      Given new_open_4_strategy
      When {
        @results = @strategy.run_command(@command)
      }
      Then {
        @results[0].should == @stdout
        @results[1].should == @stderr
        @results[2].should be @status
      }
    end

    test_that "exception_meaning_command_not_found returns Errno::ENOENT" do
      Given new_open_4_strategy
      When {
        @klass = @strategy.exception_meaning_command_not_found
      }
      Then {
        @klass.should == Errno::ENOENT
      }
    end

  private
    def new_open_4_strategy
      lambda { @strategy = Open_4.new }
    end
  end
end
