module Methadone
  # Provides #exit_now! and #help_now!.  You might mix this into your business logic classes if they will
  # need to exit the program with a human-readable error message.
  module ExitNow
    def self.included(k)
      k.extend(self)
    end
    # Call this to exit the program immediately
    # with the given error code and message.
    #
    # +exit_code+:: exit status you'd like to exit with
    # +message+:: message to display to the user explaining the problem
    #
    # If +exit_code+ is a String and +message+ is omitted, +exit_code+ will be used as the message
    # and the actual exit code will be 1.
    #
    # === Examples
    #
    #     exit_now!(4,"Oh noes!") 
    #       # => exit app with status 4 and show the user "Oh noes!" on stderr
    #     exit_now!("Oh noes!")   
    #       # => exit app with status 1 and show the user "Oh noes!" on stderr
    #     exit_now!(4)            
    #       # => exit app with status 4 and dont' give the user a message (how rude of you)
    def exit_now!(exit_code,message=nil)
      if exit_code.kind_of?(String) && message.nil?
        raise Methadone::Error.new(1,exit_code)
      else
        raise Methadone::Error.new(exit_code,message)
      end
    end

    # Exit the program as if the user made an error invoking your app, providing
    # them the message as well as printing the help.  This is useful if
    # you have complex UI validation that can't be done by OptionParser.
    def help_now!(message)
      raise OptionParser::ParseError.new(message)
    end
  end
end
