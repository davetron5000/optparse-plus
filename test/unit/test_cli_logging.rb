require 'base_test'
require 'optparse_plus'
require 'stringio'

class TestCLILogging < BaseTest
  SLEEP_TIME = 0.1

  test_that "another class using CLILogging gets the same logger instance" do
    Given {
      @first = MyClassThatLogsToStdout.new
      @second = MyOtherClassThatLogsToStdout.new
    }
    Then {
      @first.logger_id.should be == @second.logger_id
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
        self.logger=(OptparsePlus::CLILogger.new)
      end
    }
    Then {
      @logger_id.should_not be == @second.logger_id
      @first.logger_id.should be == @second.logger_id
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
      @logger_id.should_not be == @second.logger_id
      @first.logger_id.should be == @second.logger_id
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
      @app.logger.level.should be == @level
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
      @other_logger.level.should be == @level
    }
  end


  test_that "when we enable runtime log level toggling, it toggles the log level on receiving the set signal" do
    Given {
      @app = MyAppThatActsLikeItUsesMain.new
      @app.call_use_log_level_option( :toggle_debug_on_signal => 'USR2' )
      @level = Logger::INFO
      @app.use_option(@level)
    }
    When {
      send_signal_and_wait_a_moment('USR2')
    }
    Then {
      @app.logger.level.should be == Logger::DEBUG
    }
  end

  test_that "when we toggle the log level and change the logger, the new logger has also it's log level increased" do
    Given {
      @app = MyAppThatActsLikeItUsesMain.new
      @app.call_use_log_level_option( :toggle_debug_on_signal => 'USR2' )
      @level = Logger::INFO
      @app.use_option(@level)
    }
    When {
      send_signal_and_wait_a_moment('USR2')
      @other_logger = OpenStruct.new
      @app.change_logger(@other_logger)
    }
    Then {
      @other_logger.level.should be == Logger::DEBUG
    }
  end

  test_that "when we enable runtime log level toggling and send the signal twice, the original log level is restored" do
    Given {
      @app = MyAppThatActsLikeItUsesMain.new
      @app.call_use_log_level_option( :toggle_debug_on_signal => 'USR2' )
      @level = Logger::INFO
      @app.use_option(@level)
    }
    When {
      send_signal_and_wait_a_moment('USR2')
      send_signal_and_wait_a_moment('USR2')
    }
    Then {
      @app.logger.level.should be == Logger::INFO
    }
  end


  class MyAppThatActsLikeItUsesMain
    include OptparsePlus::CLILogging

    def call_use_log_level_option(args = {})
      use_log_level_option(args)
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

  class MyClassThatLogsToStdout
    include OptparsePlus::CLILogging

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
    include OptparsePlus::CLILogging

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

  def send_signal_and_wait_a_moment(signal)
    Process.kill(signal, $$)
    sleep(SLEEP_TIME) # call sleep to give the trap handler a chance to kick in
  end
end
