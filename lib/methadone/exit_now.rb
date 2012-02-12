module Methadone
  module ExitNow
    # Call this to exit the program immediately
    # with the given error code and message.
    #
    # +exit_code+:: exit status you'd like to exit with
    # +message+:: message to display to the user explaining the problem
    #
    # Also can be used without an exit code like so:
    #
    #     exit_now!("Oh noes!")
    #
    # In this case, it's equivalent to <code>exit_now!(1,"Oh noes!")</code>.
    def exit_now!(exit_code,message=nil)
      if exit_code.kind_of?(String) && message.nil?
        raise Methadone::Error.new(1,exit_code)
      else
        raise Methadone::Error.new(exit_code,message)
      end
    end
  end
end
