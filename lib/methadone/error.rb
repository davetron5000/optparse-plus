module Methadone
  # Standard exception you can throw to exit with a given 
  # status code. Generally, you should prefer Methadone::Main#exit_now! over using
  # this directly, however you may wish to create a rich hierarchy of exceptions that extend from
  # this in your app, so this is provided if you wish to do so.
  class Error < StandardError
    attr_reader :exit_code
    # Create an Error with the given status code and message
    def initialize(exit_code,message=nil)
      super(message)
      @exit_code = exit_code
    end
  end

  # Thrown by certain methods when an externally-called command exits nonzero
  class FailedCommandError < Error

    # The command that caused the failure
    attr_reader :command

    # exit_code:: exit code of the command that caused this
    # command:: the entire command-line that caused this
    # custom_error_message:: an error message to show the user instead of the boilerplate one.  Useful
    #                        for allowing this exception to bubble up and exit the program, but to give
    #                        the user something actionable.
    def initialize(exit_code,command,custom_error_message = nil)
      error_message = String(custom_error_message).empty? ?  "Command '#{command}' exited #{exit_code}" : custom_error_message
      super(exit_code,error_message)
      @command = command
    end
  end
end
