require 'base_test'
require 'methadone'
require 'stringio'

class TestCLILogging < BaseTest
  include Methadone
  
  def setup
    @blank_format = proc do |severity,datetime,progname,msg|
      msg + "\n"
    end
    @real_stderr = $stderr
    @real_stdout = $stdout
    $stderr = StringIO.new
    $stdout = StringIO.new
  end

  def teardown
    $stderr = @real_stderr
    $stdout = @real_stdout
  end

  class MyClassThatLogsToStdout
    include Methadone::CLILogging

    def initialize
      logger.formatter = proc do |severity,datetime,progname,msg|
        msg + "\n"
      end
    end

    def doit
      debug("debug")
      info("info")
      warn("warn")
      error("error")
      fatal("fatal")
    end

    def logger_id; logger.object_id; end
  end

  test "a class can include CLILogging and get terser logging" do
    MyClassThatLogsToStdout.new.doit
    $stdout.string.should == "debug\ninfo\nwarn\nerror\nfatal\n"
    $stderr.string.should == "warn\nerror\nfatal\n"
  end

  test "another class using CLILogging gets the same logger instance" do
    first = MyClassThatLogsToStdout.new
    second = MyOtherClassThatLogsToStdout.new
    first.logger_id.should == second.logger_id
  end

  test "we can change the global logger" do
    first = MyClassThatLogsToStdout.new
    second = MyOtherClassThatLogsToStdout.new
    logger_id = second.logger_id

    second.change_logger

    logger_id.should_not == second.logger_id
    first.logger_id.should == second.logger_id
  end

  test "we cannot use a nil logger" do
    lambda { MyOtherClassThatLogsToStdout.new.change_to_nil_logger }.should raise_error(ArgumentError)
  end

  class MyOtherClassThatLogsToStdout
    include Methadone::CLILogging

    def initialize
      logger.formatter = proc do |severity,datetime,progname,msg|
        msg + "\n"
      end
    end

    def doit
      debug("debug")
      info("info")
      warn("warn")
      error("error")
      fatal("fatal")
    end

    def change_logger
      self.logger=Methadone::CLILogger.new
    end

    def change_to_nil_logger
      self.logger = nil
    end

    def logger_id; logger.object_id; end
  end
end
