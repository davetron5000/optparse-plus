module Methadone
  # Include this module to gain access to the "canonical command-line app structure"
  # DSL.  This is a *very* lightweight layer on top of what you might
  # normally write that gives you just a bit of help to keep your code structured
  # in a sensible way.
  #
  # This also includes Methadone::CLILogging to give you access to simple logging
  module Main
    include Methadone::CLILogging
    # Declare the main method for your app.
    # This allows you to specify the general logic of your
    # app at the top of your bin file, but can rely on any methods
    # or other code that you define later.  
    #
    # For example, suppose you want to process a set of files, but
    # wish to determine that list from another method to keep your
    # code clean.
    #
    #     #!/usr/bin/env ruby -w
    #
    #     require 'methadone'
    #
    #     include Methadone::Main
    #
    #     main do
    #       files_to_process.each do |file|
    #         # process file
    #       end
    #     end
    #
    #     def files_to_process
    #       # return list of files
    #     end
    #
    #     go!
    #
    # The block can accept any parameters, and unparsed arguments
    # from the command line will be passed.
    # 
    # To run this method, call #go!
    def main(&block)
      @main_block = block
    end

    # Start your command-line app, exiting appropriately when
    # complete
    #
    # This *will* exit your program when it completes.  If your
    # #main block evaluates to an integer, that value will be sent
    # to Kernel#exit, otherwise, this will exit with 0
    def go!
      result = call_main
      if result.kind_of? Fixnum
        exit result
      else
        exit 0
      end
    end

    # Call this to exit the program immediately
    # with the given error code and message.
    #
    # +exit_code+:: exit status you'd like to exit with
    # +message+:: message to display to the user explaining the problem
    def exit_now!(exit_code,message=nil)
      raise Methadone::Error.new(exit_code,message)
    end

    private

    # Handle calling main and trapping any exceptions thrown
    def call_main
      @main_block.call(*ARGV)
    rescue Methadone::Error => ex
      error ex.message unless no_message? ex
      ex.exit_code
    rescue => ex
      error ex.message unless no_message? ex
      70 # Linux sysexit code for internal software error
    end

    def no_message?(exception)
      exception.message.nil? || exception.message.strip.empty?
    end
  end
end
