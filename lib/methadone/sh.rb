if RUBY_PLATFORM == 'java'
  require 'java'
  require 'ostruct'
elsif RUBY_VERSION =~ /^1.8/
  require 'open4'
else
  require 'open3'
end

module Methadone
  # Module with various helper methods for executing external commands.
  # In most cases, you can use #sh to run commands and have decent logging
  # done.  You will likely use this in a class that also mixes-in
  # Methadone::CLILogging.  If you *don't*, you must provide a logger
  # via #set_sh_logger.
  #
  # In order to work on as many Rubies as possible, this class defers the actual execution
  # to an execution strategy.  See #set_execution_strategy if you think you'd like to override
  # that, or just want to know how it works.
  #
  # This is not intended to be a complete replacement for Open3, but instead of make common cases
  # and good practice easy to accomplish.
  module SH
    # Run a shell command, capturing and logging its output.
    # If the command completed successfully, it's output is logged at DEBUG.
    # If not, its output as logged at INFO.  In either case, its
    # error output is logged at WARN.
    #
    # command:: the command to run
    # block:: if provided, will be called if the command exited nonzero.  The block may take 0, 1, or 2 arguments.
    #         The arguments provided are the standard output as a string and the standard error as a string,
    #         You should be safe to pass in a lambda instead of a block, as long as your
    #         lambda doesn't take more than two arguments
    #
    # Example
    #
    #     sh "cp foo /tmp"
    #     sh "ls /tmp" do |stdout|
    #       # stdout contains the output of ls /tmp
    #     end
    #     sh "ls -l /tmp foobar" do |stdout,stderr|
    #       # ...
    #     end
    #
    # Returns the exit status of the command.  Note that if the command doesn't exist, this returns 127.
    def sh(command,&block)
      sh_logger.debug("Executing '#{command}'")

      stdout,stderr,status = execution_strategy.run_command(command)

      sh_logger.warn("Error output of '#{command}': #{stderr}") unless stderr.strip.length == 0

      if status.exitstatus != 0
        sh_logger.info("Output of '#{command}': #{stdout}")
        sh_logger.warn("Error running '#{command}'")
      else
        sh_logger.debug("Output of '#{command}': #{stdout}") 
        call_block(block,stdout,stderr) unless block.nil?
      end

      status.exitstatus
    rescue exception_meaning_command_not_found => ex
      sh_logger.error("Error running '#{command}': #{ex.message}")
      127
    end

    # Run a command, throwing an exception if the command exited nonzero.
    # Otherwise, behaves exactly like #sh.
    #
    # Raises Methadone::FailedCommandError if the command exited nonzero.
    def sh!(command,&block)
      sh(command,&block).tap do |exitstatus|
        raise Methadone::FailedCommandError.new(exitstatus,command) if exitstatus != 0
      end
    end

    # Override the default logger (which is the one provided by CLILogging).
    # You would do this if you want a custom logger or you aren't mixing-in
    # CLILogging.
    #
    # Note that this method is *not* called <tt>sh_logger=</tt> to avoid annoying situations
    # where Ruby thinks you are setting a local variable
    def set_sh_logger(logger)
      @sh_logger = logger
    end

    # Set the strategy to use for executing commands.  In general, you don't need to set this
    # since this module chooses an appropriate implementation based on your Ruby platform:
    #
    # 1.8 Rubies, including 1.8, and REE:: Open4 is used via Methadone::ExecutionStrategy::Open_4
    # Rubinius:: Open4 is used, but we handle things a bit differently; see Methadone::ExecutionStrategy::RBXOpen_4
    # JRuby:: Use JVM calls to +Runtime+ via Methadone::ExecutionStrategy::JVM
    # Windows:: Currently no support for Windows
    # All others:: we use Open3 from the standard library, via Methadone::ExecutionStrategy::Open_3
    #
    # See Methadone::ExecutionStrategy::Base for how to implement your own.
    def set_execution_strategy(strategy)
      @execution_strategy = strategy
    end

  private 

    def exception_meaning_command_not_found
      execution_strategy.exception_meaning_command_not_found
    end

    def self.default_execution_strategy_class
      if RUBY_PLATFORM == 'java'
        Methadone::ExecutionStrategy::JVM
      elsif defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx'
        Methadone::ExecutionStrategy::RBXOpen_4
      elsif RUBY_VERSION =~ /^1.8/
        Methadone::ExecutionStrategy::Open_4
      else
        Methadone::ExecutionStrategy::Open_3
      end
    end

    def execution_strategy
      @execution_strategy ||= SH.default_execution_strategy_class.new 
    end

    def sh_logger
      @sh_logger ||= self.logger
    end

    # Safely call our block, even if the user passed in a lambda
    def call_block(block,stdout,stderr)
      # blocks that take no arguments have arity -1.  Or 0.  Ugh.
      if block.arity > 0
        case block.arity
        when 1 
          block.call(stdout)
        else
          # Let it fail for lambdas
          block.call(stdout,stderr)
        end
      else
        block.call
      end
    end
  end
end
