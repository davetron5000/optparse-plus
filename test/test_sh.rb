require 'test/unit'
require 'clean_test/test_case'

class TestSH < Clean::Test::TestCase
  include Methadone::SH
  include Methadone::CLILogging

  class CapturingLogger
    attr_reader :debugs, :infos, :warns, :errors, :fatals

    def initialize
      @debugs = []
      @infos = []
      @warns = []
      @errors = []
      @fatals = []
    end

    def debug(msg); @debugs << msg; end
    def info(msg); @infos << msg; end
    def warn(msg); @warns << msg; end
    def error(msg); @errors << msg; end
    def fatal(msg); @fatals << msg; end

  end

  [:sh,:sh!].each do |method|
    test_that "#{method} runs a successful command and logs about it" do
      Given {
        use_capturing_logger
        @command = test_command
      }
      When {
        @exit_code = self.send(method,@command)
      }
      Then {
        assert_successful_command_execution(@exit_code,@logger,@command,test_command_stdout)
      }
    end

    test_that "#{method}, when the command succeeds and given a block of one argument, gives that block the stdout" do
      Given {
        use_capturing_logger
        @command = test_command
        @stdout_received = nil
      }
      When {
        @exit_code = self.send(method,@command) do |stdout|
          @stdout_received = stdout
        end
      }
      Then {
        @stdout_received.should == test_command_stdout
        assert_successful_command_execution(@exit_code,@logger,@command,test_command_stdout)
      }
    end

    test_that "#{method}, when the command succeeds and given a block of zero arguments, calls the block" do
      Given {
        use_capturing_logger
        @command = test_command
        @block_called = false
      }
      When {
        @exit_code = self.send(method,@command) do
          @block_called = true
        end
      }
      Then {
        @block_called.should == true
        assert_successful_command_execution(@exit_code,@logger,@command,test_command_stdout)
      }
    end

    test_that "#{method}, when the command succeeds and given a lambda of zero arguments, calls the lambda" do
      Given {
        use_capturing_logger
        @command = test_command
        @block_called = false
        @lambda = lambda { @block_called = true }
      }
      When {
        @exit_code = self.send(method,@command,&@lambda)
      }
      Then {
        @block_called.should == true
        assert_successful_command_execution(@exit_code,@logger,@command,test_command_stdout)
      }
    end

    test_that "#{method}, when the command succeeds and given a block of two arguments, calls the block with the stdout and stderr" do
      Given {
        use_capturing_logger
        @command = test_command
        @block_called = false
        @stdout_received = nil
        @stderr_received = nil
      }
      When {
        @exit_code = self.send(method,@command) do |stdout,stderr|
          @stdout_received = stdout
          @stderr_received = stderr
        end
      }
      Then {
        @stdout_received.should == test_command_stdout
        @stderr_received.length.should == 0
        assert_successful_command_execution(@exit_code,@logger,@command,test_command_stdout)
      }
    end
  end

  test_that "sh, when the command fails and given a block, doesn't call the block" do
    Given {
      use_capturing_logger
      @command = test_command("foo")
      @block_called = false
    }
    When {
      @exit_code = sh @command do
        @block_called = true
      end
    }
    Then {
      @exit_code.should == 1
      assert_logger_output_for_failure(@logger,@command,test_command_stdout,test_command_stderr)
    }
  end

  test_that "sh runs a command that will fail and logs about it" do
    Given {
      use_capturing_logger
      @command = test_command("foo")
    }
    When {
      @exit_code = sh @command
    }
    Then {
      @exit_code.should == 1
      assert_logger_output_for_failure(@logger,@command,test_command_stdout,test_command_stderr)
    }
  end

  test_that "sh runs a non-existent command that will fail and logs about it" do
    Given {
      use_capturing_logger
      @command = "asdfasdfasdfas"
    }
    When {
      @exit_code = sh @command
    }
    Then {
      @exit_code.should == 127 # consistent with what bash does
      @logger.errors[0].should match /^Error running '#{@command}': .+$/
    }
  end

  test_that "sh! runs a command that will fail and logs about it, but throws an exception" do
    Given {
      use_capturing_logger
      @command = test_command("foo")
    }
    When {
      @code = lambda { sh! @command }
    }
    Then {
      exception = assert_raises(Methadone::FailedCommandError,&@code)
      exception.command.should == @command
      assert_logger_output_for_failure(@logger,@command,test_command_stdout,test_command_stderr)
    }
  end

  class MyTestApp
    include Methadone::SH
    def initialize(logger)
      set_sh_logger(logger)
    end
  end

  test_that "when we don't have CLILogging included, we can still provide our own logger" do
    Given {
      @logger = CapturingLogger.new
      @test_app = MyTestApp.new(@logger)
      @command = test_command
    }
    When {
      @exit_code = @test_app.sh @command
    }
    Then {
      assert_successful_command_execution(@exit_code,@logger,@command,test_command_stdout)
    }
  end

  class MyExecutionStrategy
    include Clean::Test::Any
    attr_reader :command

    def initialize(exitcode)
      @exitcode = exitcode
      @command = nil
    end

    def run_command(command)
      @command = command
      [any_string,any_string,OpenStruct.new(:exitstatus => @exit_code)]
    end

    def exception_meaning_command_not_found
      RuntimeError
    end
  end

  class MyExecutionStrategyApp
    include Methadone::CLILogging
    include Methadone::SH

    attr_reader :strategy

    def initialize(exit_code)
      @strategy = MyExecutionStrategy.new(exit_code)
      set_execution_strategy(@strategy)
      set_sh_logger(CapturingLogger.new)
    end
  end

  test_that "when I provide a custom execution strategy, it gets used" do
    Given {
      @exit_code = any_int :min => 0, :max => 127
      @app = MyExecutionStrategyApp.new(@exit_code)
      @command = "ls"
    }
    When {
      @results = @app.sh(@command)
    }
    Then {
      @app.strategy.command.should == @command
      @results.should == @exitstatus
    }
  end

private

  def assert_successful_command_execution(exit_code,logger,command,stdout)
    exit_code.should == 0
    logger.debugs[0].should == "Executing '#{command}'"
    logger.debugs[1].should == "Output of '#{command}': #{stdout}"
    logger.warns.length.should == 0
  end

  def assert_logger_output_for_failure(logger,command,stdout,stderr)
    logger.debugs[0].should == "Executing '#{command}'"
    logger.infos[0].should == "Output of '#{command}': #{stdout}"
    logger.warns[0].should == "Error output of '#{command}': #{stderr}"
    logger.warns[1].should == "Error running '#{command}'"
  end

  def use_capturing_logger
    @logger = CapturingLogger.new
    change_logger(@logger)
  end

  def test_command(args='')
    File.join(File.dirname(__FILE__),'command_for_tests.rb') + ' ' + args
  end

  def test_command_stdout; "standard output"; end
  def test_command_stderr; "standard error"; end

end
