module Methadone
  # Module to contain ExecutionStrategy implementations.
  # To build your own simply implement two methods:
  #
  # * <tt>run_command(command)</tt> - takes the command to run, and runs it, returning an array of size 3.  Index 0
  #                                   should be the standard output as a String (never nil), Index 1 should be the
  #                                   standard error output as a String (never nil) and Index 2 should be a 
  #                                   Process::Status representing the results of running the command.  Since it's
  #                                   not straightforward to create an instance of this class, the returned object
  #                                   in this slot need only respond to <tt>exitstatus</tt>, which returns the exit code.
  # * <tt>exception_meaning_command_not_found</tt> - return the class that, if caught, means that the underlying command
  #                                                  couldn't be found.  This is needed because currently impelmentations
  #                                                  throw an exception, but they don't all throw the same one.
  module ExecutionStrategy
    # Base strategy for MRI rubies.
    class MRI
      def run_command(command)
        raise "subclass must implement"
      end

      def exception_meaning_command_not_found
        Errno::ENOENT
      end
    end
  end
end
