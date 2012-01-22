module Methadone
  # Module to contain ExecutionStrategy implementations.
  # To build your own simply implement two methods:
  #
  # <tt>exception_meaning_command_not_found</tt>:: return the class that, if caught, means that the underlying command
  #                                                couldn't be found.  This is needed because currently impelmentations
  #                                                throw an exception, but they don't all throw the same one.
  module ExecutionStrategy
    # Base for any ExecutionStrategy implementation.  Currently, this is nothing more than an interface
    # specification.
    class Base
      # Executes the command and returns the results back.
      # This should do no logging or other logic other than to execute the command
      # and return the required results.
      #
      # command:: the command-line to run, as a String
      #
      # Returns an array of size 3:
      # <tt>[0]</tt>:: The standard output of the command as a String, never nil
      # <tt>[1]</tt>:: The standard error output of the command as a String, never nil
      # <tt>[2]</tt>:: A Process::Status-like objects that responds to <tt>exitstatus</tt> which returns
      #                the exit code of the command (e.g. 0 for success).
      def run_command(command)
        subclass_must_impelment!
      end

      # Returns the class that, if caught by calling #run_command, represents the underlying command
      # not existing.  For example, in MRI Ruby, if you try to execute a non-existent command,
      # you get a Errno::ENOENT.
      def exception_meaning_command_not_found
        subclass_must_impelment!
      end
    protected
      def subclass_must_impelment!; raise "subclass must implement"; end
    end
  end
end
