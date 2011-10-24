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

  test_that "a class can include CLILogging and get terser logging" do
    Given {
      @class_with_logger = MyClassThatLogsToStdout.new
    }

    When {
      @class_with_logger.doit
    }

    Then {
      $stdout.string.should == "debug\ninfo\nwarn\nerror\nfatal\n"
      $stderr.string.should == "warn\nerror\nfatal\n"
    }
  end

  test_that "another class using CLILogging gets the same logger instance" do
    Given {
      @first = MyClassThatLogsToStdout.new
      @second = MyOtherClassThatLogsToStdout.new
    }
    Then {
      @first.logger_id.should == @second.logger_id
    }
  end

  test_that "we can change the global logger" do
    Given {
      @first = MyClassThatLogsToStdout.new
      @second = MyOtherClassThatLogsToStdout.new
      @logger_id = @second.logger_id
    }
    When {
      @second.change_logger
    }
    Then {
      @logger_id.should_not == @second.logger_id
      @first.logger_id.should == @second.logger_id
    }
  end

  test_that "we cannot use a nil logger" do
    Given {
      @other_class = MyOtherClassThatLogsToStdout.new
    }
    Then {
      lambda { MyOtherClassThatLogsToStdout.new.change_to_nil_logger }.should raise_error(ArgumentError)
    }
  end

  class MyClassThatLogsToStdout
    include Methadone::CLILogging

    def initialize
      logger.formatter = proc do |severity,datetime,progname,msg|
        msg + "\n"
      end
      logger.level = Logger::DEBUG
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
