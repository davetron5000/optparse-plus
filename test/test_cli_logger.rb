require 'base_test'
require 'methadone'
require 'stringio'

class TestCLILogger < BaseTest
  include Methadone
  
  def setup
    @blank_format = proc { |severity,datetime,progname,msg|
      msg + "\n"
    }
    @real_stderr = $stderr
    @real_stdout = $stdout
    $stderr = StringIO.new
    $stdout = StringIO.new
  end

  def teardown
    $stderr = @real_stderr
    $stdout = @real_stdout
  end

  test_that "when both stderr and stdin are ttys, split the log messages between them and don't format" do
    Given {
      class << $stderr
        def tty?; true; end
      end
      class << $stdout
        def tty?; true; end
      end

      @logger = CLILogger.new
      @logger.level = Logger::DEBUG
    }

    When log_all_levels

    Then {
      $stdout.string.should == "debug\ninfo\n"
      $stderr.string.should == "warn\nerror\nfatal\n"
    }
  end

  test_that "logger sends debug and info to stdout, and warns, errors, and fatals to stderr" do
    Given a_logger_with_blank_format
    When log_all_levels

    Then stdout_should_have_everything
    And {
      $stderr.string.should == "warn\nerror\nfatal\n"
    }
  end

  test_that "we can control what goes to stderr" do
    Given a_logger_with_blank_format :at_error_level => Logger::Severity::FATAL

    When log_all_levels

    Then stdout_should_have_everything
    And {
      $stderr.string.should == "fatal\n"
    }
  end

  test_that "we can log to alternate devices easily" do
    Given {
      @out = StringIO.new
      @err = StringIO.new

      @logger = CLILogger.new(@out,@err)
      @logger.level = Logger::DEBUG
      @logger.formatter = @blank_format
    }

    When log_all_levels

    Then {
      @out.string.should == "debug\ninfo\nwarn\nerror\nfatal\n"
      @err.string.should == "warn\nerror\nfatal\n"
    }
  end


  test_that "error logger ignores the log level" do
    Given a_logger_with_blank_format :at_level => Logger::Severity::FATAL
    When log_all_levels

    Then {
      $stdout.string.should == "fatal\n"
      $stderr.string.should == "warn\nerror\nfatal\n"
    }
  end

  test_that "both loggers use the same date format" do
    Given {
    @logger = CLILogger.new
    @logger.level = Logger::DEBUG
    @logger.datetime_format = "the time"
    }

    When {
      @logger.debug("debug")
      @logger.error("error")
    }

    Then {
      $stdout.string.should match /the time.*DEBUG.*debug/
      $stderr.string.should match /the time.*ERROR.*error/
    }
  end

  test_that "error logger does not get <<" do
    Given a_logger_with_blank_format
    When {
      @logger << "foo"
    }
    Then {
      $stdout.string.should == "foo"
      $stderr.string.should == ""
    }
  end

  test_that "error logger can have a different format" do
    Given {
      @logger = logger_with_blank_format
      @logger.error_formatter = proc do |severity,datetime,progname,msg|
        "ERROR_LOGGER: #{msg}\n"
      end
    }
    When {
      @logger.debug("debug")
      @logger.error("error")
    }
    Then {
      $stdout.string.should == "debug\nerror\n"
      $stderr.string.should == "ERROR_LOGGER: error\n"
    }
  end

  private 

  def log_all_levels
    proc do
      @logger.debug("debug")
      @logger.info("info")
      @logger.warn("warn")
      @logger.error("error")
      @logger.fatal("fatal")
    end
  end


  def logger_with_blank_format
    logger = CLILogger.new
    logger.formatter = @blank_format
    logger.level = Logger::Severity::DEBUG
    logger
  end

  # options - :at_level - level to set the logger
  def a_logger_with_blank_format(options = {})
    proc do
      @logger = logger_with_blank_format
      @logger.level = options[:at_level] if options[:at_level]
      @logger.error_level = options[:at_error_level] if options[:at_error_level]
    end
  end

  def stdout_should_have_everything
    proc do
      $stdout.string.should == "debug\ninfo\nwarn\nerror\nfatal\n"
    end
  end


end
