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

  test "logger sends everything to stdout, and warns, errors, and fatals to stderr" do
    logger = logger_with_blank_format

    logger.debug("debug")
    logger.info("info")
    logger.warn("warn")
    logger.error("error")
    logger.fatal("fatal")

    $stdout.string.should == "debug\ninfo\nwarn\nerror\nfatal\n"
    $stderr.string.should == "warn\nerror\nfatal\n"
  end

  test "we can control what goes to stderr" do
    logger = logger_with_blank_format
    logger.error_level = Logger::Severity::FATAL

    logger.debug("debug")
    logger.info("info")
    logger.warn("warn")
    logger.error("error")
    logger.fatal("fatal")

    $stdout.string.should == "debug\ninfo\nwarn\nerror\nfatal\n"
    $stderr.string.should == "fatal\n"
  end

  test "we can log to alternate devices easily" do
    out = StringIO.new
    err = StringIO.new

    logger = CLILogger.new(out,err)
    logger.level = Logger::DEBUG
    logger.formatter = @blank_format

    logger.debug("debug")
    logger.info("info")
    logger.warn("warn")
    logger.error("error")
    logger.fatal("fatal")

    out.string.should == "debug\ninfo\nwarn\nerror\nfatal\n"
    err.string.should == "warn\nerror\nfatal\n"
  end


  test "error logger ignores the log level" do
    logger = logger_with_blank_format
    logger.level = Logger::Severity::FATAL
    logger.debug("debug")
    logger.info("info")
    logger.warn("warn")
    logger.error("error")
    logger.fatal("fatal")

    $stdout.string.should == "fatal\n"
    $stderr.string.should == "warn\nerror\nfatal\n"
  end

  test "both loggers use the same date format" do
    logger = CLILogger.new
    logger.level = Logger::DEBUG
    logger.datetime_format = "the time"
    logger.debug("debug")
    logger.error("error")
    $stdout.string.should match /the time.*DEBUG.*debug/
    $stderr.string.should match /the time.*ERROR.*error/
  end

  test "error logger does not get <<" do
    logger = logger_with_blank_format
    logger << "foo"
    $stdout.string.should == "foo"
    $stderr.string.should == ""
  end

  test "error logger can have a different format" do
    logger = logger_with_blank_format
    logger.error_formatter = proc { |severity,datetime,progname,msg|
      "ERROR_LOGGER: #{msg}\n"
    }
    logger.debug("debug")
    logger.error("error")
    $stdout.string.should == "debug\nerror\n"
    $stderr.string.should == "ERROR_LOGGER: error\n"
  end

  private 

  def logger_with_blank_format
    logger = CLILogger.new
    logger.formatter = @blank_format
    logger.level = Logger::Severity::DEBUG
    logger
  end

end
