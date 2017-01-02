require 'base_test'
require 'methadone'
require 'stringio'
require 'tempfile'

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
      $stdout.string.should be == "debug\ninfo\n"
      $stderr.string.should be == "warn\nerror\nfatal\n"
    }
  end

  test_that "when both stderr and stdin are ttys, setting the level higher than WARN should affect the error logger" do
    Given {
      class << $stderr
        def tty?; true; end
      end
      class << $stdout
        def tty?; true; end
      end

      @logger = CLILogger.new
      @logger.level = Logger::ERROR
    }

    When log_all_levels

    Then {
      $stdout.string.should be == ""
      $stderr.string.should be == "error\nfatal\n"
    }
  end

  test_that "logger sends debug and info to stdout, and warns, errors, and fatals to stderr" do
    Given a_logger_with_blank_format
    When log_all_levels

    Then stdout_should_have_everything
    And {
      $stderr.string.should be == "warn\nerror\nfatal\n"
    }
  end

  test_that "we can control what goes to stderr" do
    Given a_logger_with_blank_format :at_error_level => Logger::Severity::FATAL

    When log_all_levels

    Then stdout_should_have_everything
    And {
      $stderr.string.should be == "fatal\n"
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
      @out.string.should be == "debug\ninfo\nwarn\nerror\nfatal\n"
      @err.string.should be == "warn\nerror\nfatal\n"
    }
  end


  test_that "error logger ignores the log level" do
    Given a_logger_with_blank_format :at_level => Logger::Severity::FATAL
    When log_all_levels

    Then {
      $stdout.string.should be == "fatal\n"
      $stderr.string.should be == "warn\nerror\nfatal\n"
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
      $stdout.string.should match(/the time.*DEBUG.*debug/)
      $stderr.string.should match(/the time.*ERROR.*error/)
    }
  end

  test_that "error logger does not get <<" do
    Given a_logger_with_blank_format
    When {
      @logger << "foo"
    }
    Then {
      $stdout.string.should be == "foo"
      $stderr.string.should be == ""
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
      $stdout.string.should be == "debug\nerror\n"
      $stderr.string.should be == "ERROR_LOGGER: error\n"
    }
  end

  test_that "we can use filenames as log devices" do
    Given {
      tempfile = Tempfile.new("stderr_log")
      @stdout_file = tempfile.path
      tempfile.close

      tempfile = Tempfile.new("stdout_log")
      @stderr_file = tempfile.path
      tempfile.close
    }
    When {
      @logger = CLILogger.new(@stdout_file,@stderr_file)
      @logger.info("some info")
      @logger.error("some error")
    }
    Then {
      File.read(@stdout_file).should =~ /some info/
      File.read(@stderr_file).should =~ /some error/
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
      $stdout.string.should be == "debug\ninfo\nwarn\nerror\nfatal\n"
    end
  end


end
