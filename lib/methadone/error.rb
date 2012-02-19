module Methadone
  # Standard exception you can throw to exit with a given 
  # status code. Prefer Methadone::Main#exit_now! over this
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

    def initialize(exit_code,command,custom_error_message = nil)
      error_message = String(custom_error_message).empty? ?  "Command '#{command}' exited #{exit_code}" : custom_error_message
      super(exit_code,error_message)
      @command = command
    end
  end
end
