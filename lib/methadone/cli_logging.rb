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
  module CLILogging
    # Access the shared logger.  All classes that include this module
    # will get the same logger via this method.
    def logger
      @@logger ||= CLILogger.new
    end

    # Change the global logger that includers will use.  Useful if you
    # don't want the default configured logger.
    #
    # +new_logger+:: the new logger.  May not be nil and should be a a logger of some kind
    def logger=(new_logger)
      raise ArgumentError,"Logger may not be nil" if new_logger.nil?
      @@logger = new_logger
    end

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
  end
end
