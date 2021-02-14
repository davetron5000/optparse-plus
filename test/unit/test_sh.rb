require 'base_test'
require 'optparse_plus'

class TestSH < BaseTest
  include OptparsePlus::SH
  include OptparsePlus::CLILogging

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
    def error(msg)
      # Try to figure out what's going on on Travis
      STDERR.puts msg if RUBY_PLATFORM == 'java'
      @errors << msg
    end
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
        @stdout_received.should be == test_command_stdout
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
        @block_called.should be == true
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
        @block_called.should be == true
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
        @stdout_received.should be == test_command_stdout
        @stderr_received.length.should be == 0
        assert_successful_command_execution(@exit_code,@logger,@command,test_command_stdout)
      }
    end

    test_that "#{method}, when the command succeeds and given a block of three arguments, calls the block with the stdout, stderr, and exit code" do
      Given {
        use_capturing_logger
        @command = test_command
        @block_called = false
        @stdout_received = nil
        @stderr_received = nil
        @exitstatus_received = nil
      }
      When {
        @exit_code = self.send(method,@command) do |stdout,stderr,exitstatus|
          @stdout_received = stdout
          @stderr_received = stderr
          @exitstatus_received = exitstatus
        end
      }
      Then {
        @stdout_received.should be == test_command_stdout
        @stderr_received.length.should be == 0
        @exitstatus_received.should be == 0
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
      @exit_code.should be == 1
      assert_logger_output_for_failure(@logger,@command,test_command_stdout,test_command_stderr)
    }
  end

  test_that "sh, when the command fails with an unexpected status, and given a block, doesn't call the block" do
    Given {
      use_capturing_logger
      @command = test_command("foo")
      @block_called = false
    }
    When {
      @exit_code = sh @command, :expected => [2] do
        @block_called = true
      end
    }
    Then {
      @exit_code.should be == 1
      assert_logger_output_for_failure(@logger,@command,test_command_stdout,test_command_stderr)
    }
  end

  [1,[1],[1,2]].each do |expected|
    [:sh,:sh!].each do |method|
      test_that "#{method}, when the command fails with an expected error code (using syntax #{expected}/#{expected.class}), treats it as success" do
        Given {
          use_capturing_logger
          @command = test_command("foo")
          @block_called = false
          @exitstatus_received = nil
        }
        When {
          @exit_code = self.send(method,@command,:expected => expected) do |_,_,exitstatus|
            @block_called = true
            @exitstatus_received = exitstatus
          end
        }
        Then {
          @exit_code.should be == 1
          @block_called.should be == true
          @exitstatus_received.should be == 1
          @logger.debugs[0].should be == "Executing '#{test_command}foo'"
          @logger.debugs[1].should be == "stdout output of '#{test_command}foo': #{test_command_stdout}"
          @logger.warns[0].should be == "stderr output of '#{test_command}foo': #{test_command_stderr}"
        }
      end
    end
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
      @exit_code.should be == 1
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
      @exit_code.should be == 127 # consistent with what bash does
      @logger.errors[0].should match(/^Error running '#{@command}': .+$/)
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
      exception = assert_raises(OptparsePlus::FailedCommandError,&@code)
      exception.command.should be == @command
      assert_logger_output_for_failure(@logger,@command,test_command_stdout,test_command_stderr)
    }
  end

  test_that "sh! runs a command that will fail and includes an error message that appears in the exception" do
    Given {
      use_capturing_logger
      @command = test_command("foo")
      @custom_error_message = any_sentence
    }
    When {
      @code = lambda { sh! @command, :on_fail => @custom_error_message }
    }
    Then {
      exception = assert_raises(OptparsePlus::FailedCommandError,&@code)
      exception.command.should be == @command
      exception.message.should be == @custom_error_message
      assert_logger_output_for_failure(@logger,@command,test_command_stdout,test_command_stderr)
    }
  end

  class MyTestApp
    include OptparsePlus::SH
    def initialize(logger=nil)
      set_sh_logger(logger) if logger
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

  test_that "when we don't have CLILogging included and fail to provide a logger, an exception is thrown" do
    Given {
      @test_app = MyTestApp.new
      @command = test_command
    }
    When {
      @code = lambda { @test_app.sh @command }
    }
    Then {
      assert_raises(StandardError,&@code)
    }
  end

  class MyExecutionStrategy
    attr_reader :command

    def initialize(exitcode)
      @exitcode = exitcode
      @command = nil
    end

    def run_command(command)
      @command = command
      if @exitcode.kind_of? Integer
        ["whatever","whatever else",OpenStruct.new(:exitstatus => @exitcode)]
      else
        ["whatever","whatever else",@exitcode]
      end
    end

    def exception_meaning_command_not_found
      RuntimeError
    end
  end

  class MyExecutionStrategyApp
    include OptparsePlus::CLILogging
    include OptparsePlus::SH

    attr_reader :strategy

    def initialize(exit_code)
      @strategy = MyExecutionStrategy.new(exit_code)
      set_execution_strategy(@strategy)
      set_sh_logger(CapturingLogger.new)
    end
  end

  test_that "when I provide a custom execution strategy, it gets used" do
    Given {
      @exit_code = rand(128)
      @app = MyExecutionStrategyApp.new(@exit_code)
      @command = "ls"
    }
    When {
      @results = @app.sh(@command)
    }
    Then {
      @app.strategy.command.should be == @command
      @results.should be == @exit_code
    }
  end

  test_that "when the execution strategy returns a non-int, but truthy value, it gets coerced into a 0" do
    Given {
      @app = MyExecutionStrategyApp.new(true)
      @command = "ls"
    }
    When {
      @results = @app.sh(@command)
    }
    Then {
      @app.strategy.command.should be == @command
      @results.should be == 0
    }
  end

  test_that "when the execution strategy returns a non-int, but falsey value, it gets coerced into a 1" do
    Given {
      @app = MyExecutionStrategyApp.new(false)
      @command = "ls"
    }
    When {
      @results = @app.sh(@command)
    }
    Then {
      @app.strategy.command.should be == @command
      @results.should be == 1
    }
  end

private

  def assert_successful_command_execution(exit_code,logger,command,stdout)
    exit_code.should be == 0
    logger.debugs[0].should be == "Executing '#{command}'"
    logger.debugs[1].should be == "stdout output of '#{command}': #{stdout}"
    logger.warns.length.should be == 0
  end

  def assert_logger_output_for_failure(logger,command,stdout,stderr)
    logger.debugs[0].should be == "Executing '#{command}'"
    logger.infos[0].should be == "stdout output of '#{command}': #{stdout}"
    logger.warns[0].should be == "stderr output of '#{command}': #{stderr}"
    logger.warns[1].should be == "Error running '#{command}'"
  end

  def use_capturing_logger
    @logger = CapturingLogger.new
    change_logger(@logger)
  end

  # Runs the test command which exits with the length of ARGV/args
  def test_command(args='')
    File.join(File.expand_path(File.dirname(__FILE__)),'command_for_tests.sh') + ' ' + args
  end

  def test_command_stdout; "standard output"; end
  def test_command_stderr; "standard error"; end

end
