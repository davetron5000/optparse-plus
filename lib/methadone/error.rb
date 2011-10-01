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
end
