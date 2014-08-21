module Methadone
  # Provides easier access to a shared Methadone::CLILogger instance.
  #
  # Include this module into your class, and #logger provides access to a shared logger.
  # This is handy if you want all of your clases to have access to the same logger, but 
  # don't want to (or aren't able to) pass it around to each class.
  #
  # This also provides methods for direct logging without going through the #logger
  #
  # === Example
  #
  #     class MyClass
  #       include Methadone::CLILogger
  #       
  #       def doit
  #         debug("About to doit!")
  #         if results
  #           info("We did it!"
  #         else
  #           error("Something went wrong")
  #         end
  #         debug("Done doing it")
  #       end
  #     end
  #
  # Note that every class that mixes this in shares the *same logger instance*, so if you call #change_logger, this
  # will change the logger for all classes that mix this in.  This is likely what you want.
  module CLILogging

    def self.included(k)
      k.extend(self)
    end

    # Access the shared logger.  All classes that include this module
    # will get the same logger via this method.
    def logger
      @@logger ||= CLILogger.new
    end

    # Change the global logger that includers will use.  Useful if you
    # don't want the default configured logger.  Note that the +change_logger+
    # version is preferred because Ruby will often parse <tt>logger = Logger.new</tt> as
    # the declaration of, and assignment to, of a local variable.  You'd need to
    # do <tt>self.logger=Logger.new</tt> to be sure.  This method
    # is a bit easier.
    #
    # +new_logger+:: the new logger.  May not be nil and should be a logger of some kind
    def change_logger(new_logger)
      raise ArgumentError,"Logger may not be nil" if new_logger.nil?
      @@logger = new_logger
      @@logger.level = @log_level if @log_level
    end

    alias logger= change_logger


    # pass-through to <tt>logger.debug(progname,&block)</tt>
    def debug(progname = nil, &block); logger.debug(progname,&block); end
    # pass-through to <tt>logger.info(progname,&block)</tt>
    def info(progname = nil, &block); logger.info(progname,&block); end
    # pass-through to <tt>logger.warn(progname,&block)</tt>
    def warn(progname = nil, &block); logger.warn(progname,&block); end
    # pass-through to <tt>logger.error(progname,&block)</tt>
    def error(progname = nil, &block); logger.error(progname,&block); end
    # pass-through to <tt>logger.fatal(progname,&block)</tt>
    def fatal(progname = nil, &block); logger.fatal(progname,&block); end

    LOG_LEVELS = {
      'debug' => Logger::DEBUG,
      'info' => Logger::INFO,
      'warn' => Logger::WARN,
      'error' => Logger::ERROR,
      'fatal' => Logger::FATAL,
    }

    # Call this *if* you've included Methadone::Main to set up a <tt>--log-level</tt> option for your app
    # that will allow the user to configure the logging level. You can pass an optional hash with
    # <tt>:toggle_debug_on_signal => <SIGNAME></tt> to enable runtime toggling of the log level by sending the
    # signal <tt><SIGNAME></tt> to your app
    #
    # +args+:: optional hash
    #
    # Example:
    #
    #     main do 
    #       # your app
    #     end
    #
    #     use_log_level_option
    #
    #     go!
    #
    # Example with runtime toggling:
    #
    #
    #     main do 
    #       # your app
    #     end
    #
    #     use_log_level_option :toggle_debug_on_signal => 'USR1'
    #
    #     go!
    def use_log_level_option(args = {})
      on("--log-level LEVEL",LOG_LEVELS,'Set the logging level',
                                        '(' + LOG_LEVELS.keys.join('|') + ')',
                                        '(Default: info)') do |level|
        @log_level = level
        @log_level_original = level
        @log_level_toggled = false
        logger.level = level

        setup_toggle_trap(args[:toggle_debug_on_signal])
      end
    end

  private

    # Call this to toggle the log level between <tt>debug</tt> and its initial value
    def toggle_log_level
      @log_level_original = logger.level unless @log_level_toggled
      logger.level = if @log_level_toggled
                       @log_level_original
                     else
                       LOG_LEVELS['debug']
                     end
      @log_level_toggled = !@log_level_toggled
      @log_level = logger.level
    end

    def setup_toggle_trap(signal)
      if signal
        Signal.trap(signal) do
          toggle_log_level
        end
      end
    end
  end
end
