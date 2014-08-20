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

  test_that "we can change the global logger via self." do
    Given {
      @first = MyClassThatLogsToStdout.new
      @second = MyOtherClassThatLogsToStdout.new
      @logger_id = @second.logger_id
    }
    When {
      @second.instance_eval do
        self.logger=(Methadone::CLILogger.new)
      end
    }
    Then {
      @logger_id.should_not == @second.logger_id
      @first.logger_id.should == @second.logger_id
    }
  end

  test_that "we can change the global logger change_logger()" do
    Given {
      @first = MyClassThatLogsToStdout.new
      @second = MyOtherClassThatLogsToStdout.new
      @logger_id = @second.logger_id
    }
    When {
      @second.instance_eval do
        change_logger(Logger.new(STDERR))
      end
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
      lambda { 
        MyOtherClassThatLogsToStdout.new.instance_eval do
          self.logger=(nil)
        end
      }.should raise_error(ArgumentError)
    }
  end

  test_that "when we call use_log_level_option, it sets up logging level CLI options" do
    Given {
      @app = MyAppThatActsLikeItUsesMain.new
      @app.call_use_log_level_option
      @level = any_int
    }
    When {
      @app.use_option(@level)
    }
    Then {
      @app.logger.level.should == @level
    }
  end

  test_that "when we call use_log_level_option, then later change the logger, that logger gets the proper level set" do
    Given {
      @app = MyAppThatActsLikeItUsesMain.new
      @app.call_use_log_level_option
      @level = any_int
    }
    When {
      @app.use_option(@level)
      @other_logger = OpenStruct.new
      @app.change_logger(@other_logger)
    }
    Then {
      @other_logger.level.should == @level
    }
  end

  test_that "when we call toggle_log_level, it sets the loggers level to debug" do
    Given {
      @app = MyOtherAppThatActsLikeItUsesMain.new
      @level = Logger::INFO
      @app.call_use_log_level_option
      @app.use_option(@level)
    }
    When {
      @app.toggle_log_level
    }
    Then {
      @app.logger.level.should == Logger::DEBUG
    }
  end

  test_that "when we toggle the log level and change the logger, the new logger has also it's log level increased" do
    Given {
      @app = MyAppThatActsLikeItUsesMain.new
      @app.call_use_log_level_option
      @level = Logger::INFO
    }
    When {
      @app.use_option(@level)
      @app.toggle_log_level
      @other_logger = OpenStruct.new
      @app.change_logger(@other_logger)
    }
    Then {
      @other_logger.level.should == Logger::DEBUG
    }
  end

  test_that "when we call toggle_log_level twice, it sets the log level back to its original value" do
    Given {
      @app = MyOtherAppThatActsLikeItUsesMain.new
      @app.call_use_log_level_option
      @level = Logger::INFO
      @app.use_option(@level)
    }
    When {
      @app.toggle_log_level
      @app.toggle_log_level
    }
    Then {
      @app.logger.level.should == @level
    }
  end

  test_that "when we enable runtime log level toggling, it toggles the log level on receiving the set signal" do
    Given {
      @app = MyOtherAppThatActsLikeItUsesMain.new
      @app.call_use_log_level_option( :change_at_runtime => 'USR2' )
      @level = Logger::INFO
      @app.use_option(@level)
    }
    When {
      Process.kill('USR2', $$)
      sleep(1) # call sleep to give the trap handler a chance to kick in
    }
    Then {
      @app.logger.level.should == Logger::DEBUG
    }
  end


  class MyAppThatActsLikeItUsesMain
    include Methadone::CLILogging

    def call_use_log_level_option
      use_log_level_option
    end

    def use_option(level)
      @block.call(level)
    end

    def on(*args,&block)
      @block = block
    end

    def logger
      @logger ||= OpenStruct.new
    end
  end

  class MyOtherAppThatActsLikeItUsesMain < MyAppThatActsLikeItUsesMain
    def call_use_log_level_option(opts=nil)
      use_log_level_option(opts)
    end
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

    def logger_id; logger.object_id; end
  end
end
