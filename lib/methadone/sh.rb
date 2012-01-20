require 'open3'

module Methadone
  # Public: Module with various helper methods for executing external commands.
  # In most cases, you can use #sh to run commands and have decent logging
  # done.  You will likely use this in a class that also mixes-in
  # Methadone::CLILogging.  If you *don't*, you must provide a logger
  # via #set_sh_logger.
  #
  # This is not intended to be a complete replacement for Open3, but instead of make common cases
  # and good practice easy to accomplish.
  module SH
    # Public: Run a shell command, capturing and logging its output.
    # If the command completed successfully, it's output is logged at DEBUG.
    # If not, its output as logged at INFO.  In either case, its
    # error output is logged at WARN.
    #
    # command - the command to run
    # block   - if provided, will be called if the command exited nonzero.  The block may take 0, 1, or 2 arguments.
    #           The arguments provided are the standard output as a string and the standard error as a string,
    #           You should be safe to pass in a lambda instead of a block, as long as your
    #           lambda doesn't take more than two arguments
    #
    # Example
    #
    #   sh "cp foo /tmp"
    #   sh "ls /tmp" do |stdout|
    #     # stdout contains the output of ls /tmp
    #   end
    #   sh "ls -l /tmp foobar" do |stdout,stderr|
    #     # ...
    #   end
    #
    # Returns the exit status of the command.  Note that if the command doesn't exist, this returns 127.
    def sh(command,&block)
      sh_logger.debug("Executing '#{command}'")

      stdout,stderr,status = Open3.capture3(command)

      sh_logger.warn("Error output of '#{command}': #{stderr.chomp}")

      if status.exitstatus != 0
        sh_logger.info("Output of '#{command}': #{stdout.chomp}")
        sh_logger.warn("Error running '#{command}'")
      else
        sh_logger.debug("Output of '#{command}': #{stdout.chomp}") 
        call_block(block,stdout.chomp,stderr.chomp) unless block.nil?
      end

      status.exitstatus
    rescue Errno::ENOENT => ex
      sh_logger.error("Error running '#{command}': #{ex.message}")
      127
    end

    # Run a command, throwing an exception if the command exited nonzero.
    # Otherwise, behaves exactly like #sh
    #
    # Raises Methadone::FailedCommandError if the command exited nonzero.
    def sh!(command,&block)
      sh(command,&block).tap do |exitstatus|
        raise Methadone::FailedCommandError.new(exitstatus,command) if exitstatus != 0
      end
    end

    # Public: Override the default logger (which is the one provided by CLILogging).
    # You would do this if you want a custom logger or you aren't mixing-in
    # CLILogging.
    #
    # Note that this method is *not* called <tt>sh_logger=</tt> to avoid annoying situations
    # where Ruby thinks you are setting a local variable
    def set_sh_logger(logger)
      @sh_logger = logger
    end

  private 

    def sh_logger
      @sh_logger ||= self.logger
    end

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
