require 'logger'

module Methadone
  # A Logger appropriate for a command-line program in that it logs
  # all messages (based on level) to the standard output and logs "error" type
  # messages additionally to the standard error.  By default, this will pretty
  # much do what you want, however it can be customized:
  # 
  # * You can override the devices used by passing different devices to the constructor
  # * You can adjust the level of message that goes to the error logger via error_level=
  # * You can adjust the format for messages to the error logger separately via error_formatter=
  #
  # === Example
  #
  #     logger = CLILogger.new
  #     logger.debug("Starting up") # => only the standard output gets this
  #     logger.error("Something went wrong!") # => both standard error AND standard output get this
  class CLILogger < Logger

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
    proxy_method :add

    # A logger that logs error-type messages to a second device; useful
    # for ensuring that error messages go to standard error
    #
    # +log_device+:: device where all log messages should go, based on level
    # +error_device+:: device where all error messages should go.  By default, this is Logger::Severity::WARN
    def initialize(log_device=$stdout,error_device=$stderr)
      super(log_device)
      self.level = Logger::Severity::INFO
      @stderr_logger = Logger.new(error_device)
      @stderr_logger.level = Logger::Severity::WARN
    end

    # Set the threshold for what messages go to the error device.  Note that calling
    # #level= will *not* affect the error logger
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

  end
end
