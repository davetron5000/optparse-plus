if RUBY_PLATFORM == 'java'
  require 'java'
  require 'ostruct'
elsif RUBY_VERSION =~ /^1.8/
  begin
  require 'open4'
  rescue LoadError
    warn "For Ruby #{RUBY_VERSION}, the open4 library must be installed or SH won't work"
  end
else
  require 'open3'
end

require 'methadone/process_status'

module Methadone
  # Module with various helper methods for executing external commands.
  # In most cases, you can use #sh to run commands and have decent logging
  # done.  You will likely use this in a class that also mixes-in
  # Methadone::CLILogging (remembering that Methadone::Main mixes this in for you).  
  # If you <b>don't</b>, you must provide a logger via #set_sh_logger.
  #
  # == Examples
  #
  #    include Methadone::SH
  #
  #    sh 'cp foo.txt /tmp'
  #    # => logs the command to DEBUG, executes the command, logs its output to DEBUG and its
  #    #    error output to WARN, returns 0
  # 
  #    sh 'cp non_existent_file.txt /nowhere_good'
  #    # => logs the command to DEBUG, executes the command, logs its output to INFO and
  #    #    its error output to WARN, returns the nonzero exit status of the underlying command
  # 
  #    sh! 'cp non_existent_file.txt /nowhere_good'
  #    # => same as above, EXCEPT, raises a Methadone::FailedCommandError
  #
  #    sh 'cp foo.txt /tmp' do
  #      # Behaves exactly as before, but this block is called after
  #    end
  #
  #    sh 'cp non_existent_file.txt /nowhere_good' do
  #      # This block isn't called, since the command failed
  #    end
  #
  #    sh 'ls -l /tmp/' do |stdout|
  #      # stdout contains the output of the command
  #    end
  #    sh 'ls -l /tmp/ /non_existent_dir' do |stdout,stderr|
  #      # stdout contains the output of the command,
  #      # stderr contains the standard error output.
  #     end
  #    
  # == Handling process execution
  #
  # In order to work on as many Rubies as possible, this class defers the actual execution
  # to an execution strategy.  See #set_execution_strategy if you think you'd like to override
  # that, or just want to know how it works.
  #
  # == More complex execution and subprocess management
  #
  # This is not intended to be a complete replacement for Open3 or an enhanced means of managing subprocesses.
  # This is to make it easy for you to shell-out to external commands and have your app be robust and
  # easy to maintain.
  module SH
    def self.included(k)
      k.extend(self)
    end
    # Run a shell command, capturing and logging its output.
    # If the command completed successfully, it's output is logged at DEBUG.
    # If not, its output as logged at INFO.  In either case, its
    # error output is logged at WARN.
    #
    # command:: the command to run
    # options:: options to control the call. Currently responds to:
    #           +:expected+:: an Int or Array of Int representing error codes, <b>in addition to 0</b>, that are
    #                         expected and therefore constitute success.  Useful for commands that don't use
    #                         exit codes the way you'd like
    # block:: if provided, will be called if the command exited nonzero.  The block may take 0, 1, 2, or 3 arguments.
    #         The arguments provided are the standard output as a string, standard error as a string, and
    #         the exitstatus as an Int.
    #         You should be safe to pass in a lambda instead of a block, as long as your
    #         lambda doesn't take more than three arguments
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
    def sh(command,options={},&block)
      sh_logger.debug("Executing '#{command}'")

      stdout,stderr,status = execution_strategy.run_command(command)
      process_status = Methadone::ProcessStatus.new(status,options[:expected])

      sh_logger.warn("Error output of '#{command}': #{stderr}") unless stderr.strip.length == 0

      if process_status.success?
        sh_logger.debug("Output of '#{command}': #{stdout}") unless stdout.strip.length == 0
        call_block(block,stdout,stderr,process_status.exitstatus) unless block.nil?
      else
        sh_logger.info("Output of '#{command}': #{stdout}") unless stdout.strip.length == 0
        sh_logger.warn("Error running '#{command}'")
      end

      process_status.exitstatus
    rescue *exception_meaning_command_not_found => ex
      sh_logger.error("Error running '#{command}': #{ex.message}")
      127
    end

    # Run a command, throwing an exception if the command exited nonzero.
    # Otherwise, behaves exactly like #sh.
    #
    # options:: options hash, responding to:
    #           <tt>:expected</tt>:: same as for #sh
    #           <tt>:on_fail</tt>:: a custom error message.  This allows you to have your
    #                               app exit on shell command failures, but customize the error
    #                               message that they see.
    #
    # Raises Methadone::FailedCommandError if the command exited nonzero.
    #
    # Examples:
    #
    #     sh!("rsync foo bar")
    #     # => if command fails, app exits and user sees: "error: Command 'rsync foo bar' exited 12"
    #     sh!("rsync foo bar", :on_fail => "Couldn't rsync, check log for details")
    #     # => if command fails, app exits and user sees: "error: Couldn't rsync, check log for details
    def sh!(command,options={},&block)
      sh(command,options,&block).tap do |exitstatus|
        process_status = Methadone::ProcessStatus.new(exitstatus,options[:expected])
        unless process_status.success?
          raise Methadone::FailedCommandError.new(exitstatus,command,options[:on_fail]) 
        end
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
    # 1.8 Rubies, including 1.8, and REE:: Open4 is used via Methadone::ExecutionStrategy::Open_4. <b><tt>open4</tt> will not be
    #                                      installed as a dependency</b>.  RubyGems doesn't allow conditional dependencies, 
    #                                      so make sure that your app declares it as a dependency if you think you'll be 
    #                                      running on 1.8 or REE.
    # Rubinius:: Open4 is used, but we handle things a bit differently; see Methadone::ExecutionStrategy::RBXOpen_4.
    #            Same warning on dependencies applies.
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
    def call_block(block,stdout,stderr,exitstatus)
      # blocks that take no arguments have arity -1.  Or 0.  Ugh.
      if block.arity > 0
        case block.arity
        when 1 
          block.call(stdout)
        when 2
          block.call(stdout,stderr)
        else
          # Let it fail for lambdas
          block.call(stdout,stderr,exitstatus)
        end
      else
        block.call
      end
    end
  end
end
