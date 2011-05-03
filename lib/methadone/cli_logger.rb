require 'logger'

module Methadone
  class CLILogger < Logger

    def initialize(log_device=$stdout,error_device=$stderr)
      super(log_device)
      @stderr_logger = Logger.new(error_device)
    end

    def add(severity, message = nil, progname = nil, &block)
      super(severity,message,progname,&block)
      if severity >= Logger::Severity::WARN
        @stderr_logger.add(severity,message,progname,&block)
      end
    end

    def formatter=(formatter)
      super(formatter)
      @stderr_logger.formatter = formatter
    end
  end
end
