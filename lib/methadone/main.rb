require 'optparse'

module Methadone
  # Include this module to gain access to the "canonical command-line app structure"
  # DSL.  This is a *very* lightweight layer on top of what you might
  # normally write that gives you just a bit of help to keep your code structured
  # in a sensible way.
  #
  # You also get a more expedient interface to OptionParser.  For example, if
  # we want our app to accept a negatable switch named "switch", and a flag
  # named "flag", we can do the following:
  #
  #     #!/usr/bin/env ruby -w
  #       
  #     require 'methadone'
  #      
  #     include Methadone::Main
  #     
  #     main do
  #       options[:switch] => true or false, based on command line
  #       options[:flag] => value of flag passed on command line
  #     end
  #     
  #     # Proxy to an OptionParser instance's on method
  #     on("--[no]-switch")
  #     on("--flag VALUE")
  #     
  #     go!
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
      @options = {}
      @option_parser = OptionParserProxy.new(OptionParser.new,@options)
    end


    # Start your command-line app, exiting appropriately when
    # complete
    #
    # This *will* exit your program when it completes.  If your
    # #main block evaluates to an integer, that value will be sent
    # to Kernel#exit, otherwise, this will exit with 0
    def go!
      opts.parse!
      result = call_main
      if result.kind_of? Fixnum
        exit result
      else
        exit 0
      end
    rescue OptionParser::ParseError => ex
      error ex.message
      exit 1
    end

    # Call this to exit the program immediately
    # with the given error code and message.
    #
    # +exit_code+:: exit status you'd like to exit with
    # +message+:: message to display to the user explaining the problem
    def exit_now!(exit_code,message=nil)
      raise Methadone::Error.new(exit_code,message)
    end

    # Returns an OptionParser that you can use
    # to declare your command-line interface.  The object returned as
    # an additional feature that implements typical use of OptionParser.
    #
    #     opts.on("--flag VALUE")
    #
    # Does this under the covers:
    #
    #     opts.on("--flag VALUE") do |value|
    #       options[:flag] = value
    #     end
    #
    # Since, most of the time, this is all you want to do,
    # this makes it more expedient to do so.  The key that is
    # is set in #options will be a symbol of the option name, without
    # the dashes.  Note that if you use multiple option names, a key
    # will be generated for each.  Further, if you use the negatable form,
    # only the positive key will be set, e.g. for <tt>--[no-]verbose</tt>,
    # only <tt>:verbose</tt> will be set (to true or false).
    def opts
      @option_parser
    end

    # Calls <tt>opts.on</tt> with the given arguments
    def on(*args,&block)
      opts.on(*args,&block)
    end

    # Returns a Hash that you can use to store or retrieve options
    # parsed from the command line
    def options
      @options
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

  # A proxy to OptionParser that intercepts #on
  # so that we can allow a simpler interface
  class OptionParserProxy < BasicObject
    # Create the proxy
    #
    # +option_parser+:: An OptionParser instance
    # +options+:: a hash that will store the options
    #             set via automatic setting.  The caller should
    #             retain a reference to this
    def initialize(option_parser,options)
      @option_parser = option_parser
      @options = options
    end

    # If invoked as with OptionParser, behaves the exact same way.
    # If invoked without a block, however, the options hash given
    # to the constructor will be used to store
    # the parsed command-line value.  See #opts in the Main module
    # for how that works.
    def on(*args,&block)
      if block
        @option_parser.on(*args,&block)
      else
        opt_names = option_names(*args)
        @option_parser.on(*args) do |value|
          opt_names.each { |name| @options[name] = value }
        end
      end
    end

    # Defers all calls save #on to 
    # the underlying OptionParser instance
    def method_missing(sym,*args,&block)
      @option_parser.send(sym,*args,&block)
    end

    private

    def option_names(*opts_on_args,&block)
      opts_on_args.map { |arg|
        if arg =~ /^--\[no-\]([^-\s]*)/
          $1.to_sym
        elsif arg =~ /^--([^-\s]*)/
          $1.to_sym
        elsif arg =~ /^-([^-\s]*)/
          $1.to_sym
        else
          nil
        end
      }.reject(&:nil?)
    end

  end
end
