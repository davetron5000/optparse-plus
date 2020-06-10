require 'logger'

module OptparsePlus
  # A Logger instance that gives better control of messaging the user
  # and logging app activity.  At it's most basic, you would use <tt>info</tt>
  # as a replacement for +puts+ and <tt>error</tt> as a replacement
  # for <tt>STDERR.puts</tt>.  Since this is a logger, however, you
  # can also use #debug, #warn, and #fatal, and you can control
  # the format and "logging level" as such.
  #
  # So, by default:
  # * debug messages do not appear anywhere
  # * info messages appear on the standard output
  # * warn, error, and fatal messagse appear on the standard error
  # * The default format of messages is simply the message, no logging cruft, however if your output
  #   is redirected to a file, a better timestamped logging format is used
  #
  # You can customize this in several ways:
  #
  # * You can override the devices used by passing different devices to the constructor
  # * You can adjust the level of message that goes to the error logger via error_level=
  # * You can adjust the format for messages to the error logger separately via error_formatter=
  #
  # === Example
  #
  #     logger = CLILogger.new
  #     logger.debug("Starting up") # => only the standard output gets this
  #     logger.warn("careful!") # => only the standard error gets this
  #     logger.error("Something went wrong!") # => only the standard error gets this
  #
  #     logger = CLILogger.new
  #     logger.error_level = Logger::ERROR
  #     logger.debug("Starting up") # => only the standard output gets this
  #     logger.warn("careful!") # => only the standard OUTPUT gets this
  #     logger.error("Something went wrong!") # => only the standard error gets this
  #
  #     logger = CLILogger.new('logfile.txt')
  #     logger.debug("Starting up") # => logfile.txt gets this
  #     logger.error("Something went wrong!") # => BOTH logfile.txt AND the standard error get this
  class CLILogger < Logger
    BLANK_FORMAT = proc { |severity,datetime,progname,msg|
      msg + "\n"
    }

    # Helper to proxy methods to the super class AND to the internal error logger
    #
    # +symbol+:: Symbol for name of the method to proxy
    def self.proxy_method(symbol) #:nodoc:
      old_name = "old_#{symbol}".to_sym
      alias_method old_name,symbol
      define_method symbol do |*args,&block|
        send(old_name,*args,&block)
        @stderr_logger.send(symbol,*args,&block)
      end
    end

    proxy_method :'formatter='
    proxy_method :'datetime_format='

    def add(severity, message = nil, progname = nil, &block) #:nodoc:
      if @split_logs
        unless severity >= @stderr_logger.level
          super(severity,message,progname,&block)
        end
      else
        super(severity,message,progname,&block)
      end
      @stderr_logger.add(severity,message,progname,&block)
    end

    DEFAULT_ERROR_LEVEL = Logger::Severity::WARN

    # A logger that logs error-type messages to a second device; useful
    # for ensuring that error messages go to standard error.  This should be
    # pretty smart about doing the right thing.  If both log devices are
    # ttys, e.g. one is going to standard error and the other to the standard output,
    # messages only appear once in the overall output stream.  In other words,
    # an ERROR logged will show up *only* in the standard error.  If either
    # log device is NOT a tty, then all messages go to +log_device+ and only
    # errors go to +error_device+
    #
    # +log_device+:: device where all log messages should go, based on level
    # +error_device+:: device where all error messages should go.  By default, this is Logger::Severity::WARN
    def initialize(log_device=$stdout,error_device=$stderr)
      @stderr_logger = Logger.new(error_device)

      super(log_device)

      log_device_tty   = tty?(log_device)
      error_device_tty = tty?(error_device)

      @split_logs = log_device_tty && error_device_tty

      self.level = Logger::Severity::INFO
      @stderr_logger.level = DEFAULT_ERROR_LEVEL

      self.formatter = BLANK_FORMAT if log_device_tty
      @stderr_logger.formatter = BLANK_FORMAT if error_device_tty
    end

    def level=(level)
      super(level)
      if (level > DEFAULT_ERROR_LEVEL) && @split_logs
        @stderr_logger.level = level
      end
    end

    # Set the threshold for what messages go to the error device.  Note that calling
    # #level= will *not* affect the error logger *unless* both devices are TTYs.
    #
    # +level+:: a constant from Logger::Severity for the level of messages that should go
    #           to the error logger
    def error_level=(level)
      @stderr_logger.level = level
    end

    # Overrides the formatter for the error logger.  A future call to #formatter= will
    # affect both, so the order of the calls matters.
    #
    # +formatter+:: Proc that handles the formatting, the same as for #formatter=
    def error_formatter=(formatter)
      @stderr_logger.formatter=formatter
    end

  private

    def tty?(device_or_string)
      return device_or_string.tty? if device_or_string.respond_to? :tty?
      false
    end

  end
end
