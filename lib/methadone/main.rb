require 'optparse'
require 'yaml'

begin
  Module.const_get('BasicObject')
  # We are 1.9.x
rescue NameError
  BasicObject = Object
end

module Methadone
  # Include this module to gain access to the "canonical command-line app structure"
  # DSL.  This is a *very* lightweight layer on top of what you might
  # normally write that gives you just a bit of help to keep your code structured
  # in a sensible way.  You can use as much or as little as you want, though
  # you must at least use #main to get any benefits.
  #
  # Further, you must provide access to a logger via a method named
  # #logger.  If you include Methadone::CLILogging, this will be done for you
  #
  # You also get a more expedient interface to OptionParser as well
  # as checking for required arguments to your app.  For example, if
  # we want our app to accept a negatable switch named "switch", a flag
  # named "flag", and two arguments "needed" (which is required)
  # and "maybe" which is optional, we can do the following:
  #
  #     #!/usr/bin/env ruby
  #
  #     require 'methadone'
  #
  #     class App
  #       include Methadone::Main
  #       include Methadone::CLILogging
  #
  #       main do |needed, maybe|
  #         options[:switch] => true or false, based on command line
  #         options[:flag] => value of flag passed on command line
  #       end
  #
  #       # Proxy to an OptionParser instance's on method
  #       on("--[no]-switch")
  #       on("--flag VALUE")
  #
  #       arg :needed
  #       arg :maybe, :optional
  #
  #       defaults_from_env_var SOME_VAR
  #       defaults_from_config_file '.my_app.rc'
  #
  #       go!
  #     end
  #
  # Our app then acts as follows:
  #
  #     $ our_app
  #     # => parse error: 'needed' is required
  #     $ our_app foo
  #     # => succeeds; "maybe" in main is nil
  #     $ our_app --flag foo
  #     # => options[:flag] has the value "foo"
  #     $ SOME_VAR='--flag foo' our_app
  #     # => options[:flag] has the value "foo"
  #     $ SOME_VAR='--flag foo' our_app --flag bar
  #     # => options[:flag] has the value "bar"
  #
  # Note that we've done all of this inside a class that we called +App+.  This isn't strictly
  # necessary, and you can just +include+ Methadone::Main and Methadone::CLILogging at the root
  # of your +bin+ file if you like.  This is somewhat unsafe, because +self+ inside the +bin+
  # file is Object, and any methods you create (or cause to be created via +include+) will be
  # present on *every* object.  This can cause odd problems, so it's recommended that you
  # *not* do this.
  #
  # Subcommands
  # -----------
  #
  # In order to promote modularity and maintainability, complex command line
  # applications should be broken up into subcommands.  Subcommands are just
  # like regular Methadone applications, except you don't put a go! call in it.
  # It will be run in by the base methadone app class.  Likewise, subcommands
  # can have subcommands of their own.
  #
  # In order to tell a Methadone app class that it has subcommands, use the
  # command method, which takes a hash with the command name as a key and the
  # command class as the value.  Multiple subcommands can be specified in a
  # single call, or as separate calls.
  #
  #     #!/usr/bin/env ruby
  #
  #     require 'methadone'
  #
  #     class MySubcommand
  #       include Methadone::Main
  #       include Methadone::CLILogging
  #
  #       on '-f','--foo BAR', 'Some option'
  #       arg 'something', :required, "Description","defaults: value"
  #
  #       main do |something|
  #        # stuff
  #       end
  #     end
  #
  #     class App
  #       include Methadone::Main
  #       include Methadone::CLILogging
  #
  #       command "do" => MySubcommand
  #
  #       go!
  #     end
  #
  # Apps that have subcommands (currently) don't support arguments and don't
  # need to supply a main, as it doesn't get called.  This may change in a
  # future version of Methadone.  Options to the app can modify the +options+
  # contents will impactful to the subcommand as it receives those option
  # values as the base for its options.
  #
  module Main
    include Methadone::ExitNow
    include Methadone::ARGVParser

    def self.included(k)
      k.extend(self)
    end

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
    # *Note*: #go! will modify +ARGV+ to remove any known options and
    # arguments.  If there are any values left over, they will remain available
    # in +ARGV+.
    #
    # To run this method, call #go!
    def main(&block)
      @main_block = block
    end

    # Configure the auto-handling of StandardError exceptions caught
    # from calling go!.
    #
    # leak:: if true, go! will *not* catch StandardError exceptions, but
    #        instead allow them to bubble up.  If false, they will be caught
    #        and handled as normal.  This does *not* affect Methadone::Error
    #        exceptions; those will NOT leak through.
    #
    #        leak_exceptions only needs to be set once; since it is stored as a
    #        class variable, all classes that include this module will handle
    #        exceptions the same way.
    def leak_exceptions(leak)
      @@leak_exceptions = leak
    end

    # Print the usage help if the command is run without any options or
    # arguments.
    def help_if_bare
      @default_help = true
    end

    # Set the name of the environment variable where users can place default
    # options for your app.  Omit this to disable the feature.
    def defaults_from_env_var(env_var)
      @env_var = env_var
    end

    # Set the path to the file where defaults can be configured.
    #
    # The format of this file can be either a simple string of options, like what goes
    # in the environment variable (see #defaults_from_env_var), or YAML, in which case
    # it should be a hash where keys are the option names, and values their defaults.
    #
    # Relative paths will be expanded relative to the user's home directory.
    #
    # filename:: path to the file.  If relative, will look in user's HOME directory.
    #            If absolute, this is the absolute path to where the file should be.
    def defaults_from_config_file(filename,options={})
      @rc_file = File.expand_path(filename, ENV['HOME'])
    end

    # Start your command-line app, exiting appropriately when
    # complete.
    #
    # This *will* exit your program when it completes.  If your
    # #main block evaluates to an integer, that value will be sent
    # to Kernel#exit, otherwise, this will exit with 0
    #
    # If the command-line options couldn't be parsed, this
    # will exit with 64 and whatever message OptionParser provided.
    #
    # If a required argument (see #arg) is not found, this exits with
    # 64 and a message about that missing argument.
    #
    def go!(parent=nil)
      if @default_help and ARGV.empty?
        puts opts.to_s
        exit 64 # sysexits.h exit code EX_USAGE
      end

      # Get stuff from parent, if there
      set_parent(parent)

      setup_defaults
      opts.post_setup

      if opts.commands.empty?
        opts.parse!
        opts.check_args!
        opts.check_option_usage!
        result = call_main
      else
        opts.parse_to_command! # Leaves unknown args and options in once it encounters a non-option.
        opts.check_option_usage!
        if opts.selected_command
          result = call_provider
        else
          logger.error "You must specify a command"
          puts ""
          puts opts.help
          exit 64
        end
      end

      if result.kind_of? Fixnum
        exit result
      else
        exit 0
      end
    rescue OptionParser::ParseError => ex
      logger.error ex.message
      puts
      puts opts.help
      exit 64 # Linux standard for bad command line
    end

    # Returns an OptionParser that you can use
    # to declare your command-line interface.  Generally, you
    # won't use this and will use #on directly, but this allows
    # you to have complete control of option parsing.
    #
    # The object returned has
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
    # Since, most of the time, this is all you want to do, this makes it more
    # expedient to do so.  The key that is is set in #options will be a symbol
    # <i>and string</i> of the option name, without the leading dashes.  Note
    # that if you use multiple option names, a key will be generated for each.
    # Further, if you use the negatable form, only the positive key will be set,
    # e.g. for <tt>--[no-]verbose</tt>, only <tt>:verbose</tt> will be set (to
    # true or false).
    #
    # As an example, this declaration:
    #
    #     opts.on("-f VALUE", "--flag")
    #
    # And this command-line invocation:
    #
    #     $ my_app -f foo
    #
    # Will result in all of these forms returning the String "foo":
    # * <tt>options['f']</tt>
    # * <tt>options[:f]</tt>
    # * <tt>options['flag']</tt>
    # * <tt>options[:flag]</tt>
    #
    # Further, any one of those keys can be used to determine the default value for the option.
    #
    # Playing well with others
    # ------------------------
    #
    # Sometimes you need the user to specify groups of options, or sometimes
    # one option cannot be used in conjunction with another option.  While
    # OptionParser does not natively support this, options defined with
    # Methadone's +on+ method does so by using the following hash arguments:
    #
    #   :excludes => <optID>
    #   :requires => <optID>
    #
    # The optID can be any of the keys that an option would create in the
    # options hash.  You can even specify multiple options by using an array of
    # optIDs:
    #
    #   :excludes => [:f, "another-option"]
    #
    # If you specify both an option and another option that excludes that
    # option, an error is logged.  Only one side of an exclusion needs to be
    # specified.
    #
    # If you use an option, but do not use an option it requires, an error will
    # be logged.  Order of the options do not matter.
    #
    def opts
      @option_parser ||= OptionParserProxy.new(OptionParser.new,options)
    end

    # Calls the +on+ method of #opts with the given arguments (see RDoc for #opts for the additional
    # help provided).
    def on(*args,&block)
      opts.on(*args,&block)
    end

    # Calls the +command+ method of #opts with the given arguments (see RDoc
    # for #opts for the additional help provided).  Commands are special args
    # that take their own options and other arguments.
    def command(*args)
      opts.command(*args)
    end

    # Sets the name of an arguments your app accepts.
    # +arg_name+:: name of the argument to appear in documentation
    #              This will be converted into a String and used to create
    #              the banner (unless you have overridden the banner)
    # +options+:: list (not Hash) of options:
    #             <tt>:required</tt>:: this arg is required (this is the default)
    #             <tt>:optional</tt>:: this arg is optional
    #             <tt>:one</tt>:: only one of this arg should be supplied (default)
    #             <tt>:many</tt>::  many of this arg may be supplied, but at least one is required
    #             <tt>:any</tt>:: any number, include zero, may be supplied
    #             A string:: if present, this will be documentation for the
    #                        argument and appear in the help.  Multiple strings will be
    #                        listed on multiple lines
    #             A Regexp:: Argument values must match the regexp, or an error will be raised.
    #             An Array:: Argument values must be found in the array, or an error will be raised.
    #
    #  As of version 2.0, best effort is made to ensure values are assigned to
    #  your arguments as needed.  :required and :many options will take one
    #  value if possible, and the first greedy argument (:many or :any) will
    #  consume any unallocated count of values remaining in ARGV.  Value
    #  assignment still goes left to right, but allocation counts are determined
    #  by needs of each argument.  Filtering rules do not play a part in
    #  determining if a value can be allocated to an argument.
    #
    #  Greedy arguments that do not receive any values will hold an empty
    #  array, while non-greedy arguments that do not receive a value will be
    #  nil.
    def arg(arg_name,*options)
      opts.arg(arg_name,*options)
    end

    # Set the description of your app for inclusion in the help output.
    # +desc+:: a short, one-line description of your app
    def description(desc=nil)
      opts.description(desc)
    end

    # Returns a Hash that you can use to store or retrieve options
    # parsed from the command line.  When you put values in here, if you do so
    # *before* you've declared your command-line interface via #on, the value
    # will be used in the docstring to indicate it is the default.
    # You can use either a String or a Symbol and, after #go! is called and
    # the command-line is parsed, the values will be available as both
    # a String and a Symbol.
    #
    # Example
    #
    #     main do
    #       puts options[:foo] # put the value of --foo that the user provided
    #     end
    #
    #     options[:foo] = "bar" # set "bar" as the default value for --foo, which
    #                           # will cause us to include "(default: bar)" in the
    #                           # docstring
    #
    #     on("--foo FOO","Sets the foo")
    #     go!
    #
    def options
      @options ||= {}
    end

    def global_options
      (@parent.nil? ? {} : @parent.global_options).merge(
        opts.global_options
      )
    end

    # Set the version of your app so it appears in the
    # banner.  This also adds --version as an option to your app which,
    # when used, will act just like --help (see version_options to control this)
    #
    # version:: the current version of your app.  Should almost always be
    #           YourApp::VERSION, where the module YourApp should've been generated
    #           by the bootstrap script
    # version_options:: controls how the version option behaves.  If this is a string,
    #                   then the string will be used as documentation for the --version flag.
    #                   If a Hash, more configuration is available:
    #                   custom_docs:: the string to document the --version flag if you don't like the default
    #                   compact:: if true, --version will just show the app name and version - no help
    #                   format:: if provided, this can give limited control over the format of the compact
    #                            version string.  It should be a printf-style string and will be given
    #                            two options: the first is the CLI app name, and the second is the version string
    def version(version,version_options={})
      opts.version(version)
      if version_options.kind_of?(Symbol)
        case version_options
        when :terse
          version_options = {
            :custom_docs => "Show version",
            :format => '%0.0s%s',
            :compact => true
          }
        when :basic
          version_options = {
            :custom_docs => "Show version info",
            :compact => true
          }
        else
          version_options = version_options.to_s
        end
      end

      if version_options.kind_of?(String)
        version_options = { :custom_docs => version_options }
      end
      version_options[:custom_docs] ||= "Show help/version info"
      version_options[:format] ||= "%s version %s"
      opts.on("--version",version_options[:custom_docs]) do
        if version_options[:compact]
          puts version_options[:format] % [::File.basename($0),version]
        else
          puts opts.to_s
        end
        exit 0
      end
    end

    private

    # Reset internal state - mostly useful for tests
    def reset!
      @options = nil
      @option_parser = nil
    end

    def setup_defaults
      add_defaults_to_docs
      set_defaults_from_rc_file
      normalize_defaults
      set_defaults_from_env_var
    end

    def set_parent(parent)
      @parent = parent
      if parent
        @options.merge!(parent.global_options)
        opts.extend_help_from_parent(parent.opts)
      end
    end

    def add_defaults_to_docs

      # Remove any pre-existing separator text
      opts.top.list.reject! {|v| v.is_a? String}

      if @env_var && @rc_file
        opts.separator ''
        opts.separator 'Default values can be placed in:'
        opts.separator ''
        opts.separator "    #{@env_var} environment variable, as a String of options"
        opts.separator "    #{@rc_file} with contents either a String of options "
        spaces = (0..@rc_file.length).reduce('') { |a,_| a << ' ' }
        opts.separator "    #{spaces}or a YAML-encoded Hash"
      elsif @env_var
        opts.separator ''
        opts.separator "Default values can be placed in the #{@env_var} environment variable"
      elsif @rc_file
        opts.separator ''
        opts.separator "Default values can be placed in #{@rc_file}"
      end
    end

    def set_defaults_from_env_var
      if @env_var
        parse_string_for_argv(ENV[@env_var]).each do |arg|
          ::ARGV.unshift(arg)
        end
      end
    end

    def set_defaults_from_rc_file
      if @rc_file && File.exists?(@rc_file)
        File.open(@rc_file) do |file|
          parsed = YAML::load(file)
          if parsed.kind_of? String
            parse_string_for_argv(parsed).each do |arg|
              ::ARGV.unshift(arg)
            end
          elsif parsed.kind_of? Hash
            parsed.each do |option,value|
              options[option] = value
            end
          else
            raise OptionParser::ParseError,
              "rc file #{@rc_file} is not parseable, should be a string or YAML-encoded Hash"
          end
        end
      end
    end


    # Normalized all defaults to both string and symbol forms, so
    # the user can access them via either means just as they would for
    # non-defaulted options
    def normalize_defaults
      new_options = {}
      options.each do |key,value|
        unless value.nil?
          new_options[key.to_s] = value
          new_options[key.to_sym] = value
        end
      end
      options.merge!(new_options)
    end

    # Handle calling main and trapping any exceptions thrown
    def call_main
      # Backwards compatibility ensured by adding ::ARGV
      # TBD: rework spec so that unspecified args need to be retrieved from ARGV directly and not just passed into main
      @main_block.call(*(opts.args_for_main))
    rescue Methadone::Error => ex
      raise ex if ENV['DEBUG']
      logger.error ex.message unless no_message? ex
      ex.exit_code
    rescue OptionParser::ParseError
      raise
    rescue => ex
      raise ex if ENV['DEBUG']
      raise ex if @@leak_exceptions
      logger.error ex.message unless no_message? ex
      70 # Linux sysexit code for internal software error
    end

    def no_message?(exception)
      exception.message.nil? || exception.message.strip.empty?
    end

    def call_provider
      command = opts.selected_command
      opts.commands[command].send(:go!,self)
    end
  end

  # <b>Methadone Internal - treat as private</b>
  #
  # A proxy to OptionParser that intercepts #on
  # so that we can allow a simpler interface
  class OptionParserProxy < Object
    # Create the proxy
    #
    # +option_parser+:: An OptionParser instance
    # +options+:: a hash that will store the options
    #             set via automatic setting.  The caller should
    #             retain a reference to this
    def initialize(option_parser,options)
      @option_parser = option_parser
      @options = options
      @option_defs ||= {:local => [],:global => []}
      @option_sigs = {}
      @options_used = []
      @usage_rules = {}
      @commands = {}
      @selected_command = nil
      @user_specified_banner = false
      @accept_options = false
      @args = []
      @arg_options = {}
      @arg_filters = {}
      @arg_documentation = {}
      @args_by_name = {}
      @description = nil
      @version = nil
      @banner_stale = true
      document_help
    end

    def parent_opts=(parent_opts)
      @parent_opts = parent_opts
    end

    def parent_opts
      @parent_opts || nil
    end

    def global_options
      global_option_defs = @option_defs.fetch(:global, nil)
      return {} if global_option_defs.nil?

      keys = global_option_defs.map {|opt_def|
        [opt_def.long, opt_def.short].
          flatten.
          map {|flag| flag.sub(/^--?(\[no-\])?/,'')}.
          map {|flag| [flag,flag.to_sym]}
      }.flatten
      global_hash = @options.select {|k,v| keys.include? k}
      global_hash.is_a?(Array) ? Hash[global_hash] : global_hash # Stupid 1.8.7 => 1.9.3 API change of Hash#select
    end

    def check_args!
      arg_allocation_map = @args.map {|arg_name| @arg_options[arg_name].include?(:required) ? 1 : 0}

      arg_count = ::ARGV.length - arg_allocation_map.reduce(0,&:+)
      if arg_count > 0
        @args.each.with_index do |arg_name,i|
          if (@arg_options[arg_name] & [:many,:any]).length > 0
            arg_allocation_map[i] += arg_count
            break
          elsif @arg_options[arg_name].include? :optional
            arg_allocation_map[i] += 1
            arg_count -= 1
            break if arg_count == 0
          end
        end
      end

      @args.zip(arg_allocation_map).each do |arg_name,arg_count|
        if not (@arg_options[arg_name] & [:many,:any]).empty?
          arg_value = ::ARGV.shift(arg_count)
        else
          arg_value = (arg_count == 1) ? ::ARGV.shift : nil
        end

        if @arg_options[arg_name].include? :required and arg_value.nil?
          message = "'#{arg_name.to_s}' is required"
          raise ::OptionParser::ParseError,message
        elsif @arg_options[arg_name].include?(:many) and arg_value.empty?
          message = "at least one '#{arg_name.to_s}' is required"
          raise ::OptionParser::ParseError,message
        end

        unless arg_value.nil? or arg_value.empty? or @arg_filters[arg_name].empty?
          match = false
          msg = ''
          @arg_filters[arg_name].each do |filter|
            if not (@arg_options[arg_name] & [:many,:any]).empty?
              if filter.respond_to? :include?
                invalid_values = (filter | arg_value) - filter
              elsif filter.is_a? ::Regexp
                invalid_values = arg_value - arg_value.grep(filter)
              end
              if invalid_values.empty?
                match = true
                break
              end
              msg = "The following value(s) were invalid: '#{invalid_values.join(' ')}'"
            else
              if filter.respond_to? :include?
                if filter.include? arg_value
                  match = true
                  break
                end
              elsif filter.is_a?(::Regexp)
                if arg_value =~ filter
                  match = true
                  break
                end
              end
              msg = "'#{arg_value}' is invalid"
            end
          end

          raise ::OptionParser::ParseError, "#{arg_name}: #{msg}" unless match

        end
        @args_by_name[arg_name] = arg_value
      end
    end

    def args_for_main
      @args.map {|name| @args_by_name[name]}
    end

    # If invoked as with OptionParser, behaves the exact same way.
    # If invoked without a block, however, the options hash given
    # to the constructor will be used to store
    # the parsed command-line value.  See #opts in the Main module
    # for how that works.
    # Returns reference to the option for exclusive and mutual
    def on(*args,&block)

      # Group together any of the hash arguments
      (hashes, args) = args.partition {|a| a.respond_to?(:keys)}
      on_opts = hashes.reduce({}) {|h1,h2| h1.merge(h2)}

      scope = args.delete(:global) || :local
      args = add_default_value_to_docstring(*args)
      sig = option_signature(args)
      opt_names = option_names(*args)

      opt_names.each do |name|
        @option_sigs[name] = sig
      end

      block ||= Proc.new do |value|
        opt_names.each do |name|
          @options[name] = value
        end
      end
      wrapper = Proc.new do |value|
        register_usage opt_names
        block.call(value)
      end

      opt = @option_parser.define(*args,&wrapper)
      @option_defs[scope] << opt

      set_usage_rules_for(opt_names,on_opts)

      @accept_options = true
      @banner_stale = true
    end

    def set_usage_rules_for(names,rules_source)
      rule_keys = [:excludes, :requires]
      rules = Hash[rule_keys.zip(rules_source.values_at(*rule_keys))].reject{|k,v| v.nil?}
      return if rules.empty?

      names.each do |name|
        @usage_rules[name] = rules
      end
    end

    def register_usage(opt_names)
      opt_names.each do |name|
        @options_used << name
      end
    end

    def check_option_usage!
      requirers = @options_used.select {|name| @usage_rules.fetch(name,{}).key?(:requires)}
      requirers.each do |name|
        required = [@usage_rules[name][:requires]].flatten
        violation = required - @options_used
        unless violation.empty?
          raise OptionParser::OptionConflict.new("Missing option #{@option_sigs[violation.first]} required by option #{@option_sigs[name]}")
        end
      end
      excluders = @options_used.select {|name| @usage_rules.fetch(name,{}).key?(:excludes)}
      excluders.each do |name|
        excluded = [@usage_rules[name][:excludes]].flatten
        violation = (excluded & @options_used)
        unless violation.empty?
          raise OptionParser::OptionConflict, "#{@option_sigs[name]} cannot be used if already using #{@option_sigs[violation.first]}"
        end
      end
    end

    # Specify an acceptable command that will be hanlded by the given command provider
    def command(provider_hash={})
      provider_hash.each do |name,cls|
        raise InvalidProvider.new("Provider for #{name} must respond to go!") unless cls.respond_to? :go!
        commands[name.to_s] = cls
      end
      @banner_stale = true
    end

    # Proxies to underlying OptionParser
    def banner=(new_banner)
      @option_parser.banner=new_banner
      @user_specified_banner = true
    end

    # Sets the banner to include these arg names
    def arg(arg_name,*options)
      options << :optional if options.include?(:any) && !options.include?(:optional)
      options << :required unless options.include? :optional
      options << :one unless options.include?(:any) || options.include?(:many)
      @args << arg_name
      @arg_options[arg_name] = options
      @arg_documentation[arg_name]= options.select(&STRINGS_ONLY)
      @arg_filters[arg_name] = options.select {|o| o.is_a?(Array) or o.is_a?(Range) or o.is_a?(::Regexp)}
      @banner_stale = true
    end

    def description(desc)

      @description = desc if desc
      @banner_stale = true
      @description
    end

    # Defers all calls save #on to
    # the underlying OptionParser instance
    def method_missing(sym,*args,&block)
      @option_parser.send(sym,*args,&block)
    end

    def banner
      set_banner if @banner_stale
      @option_parser.banner
    end

    def help
      set_banner if @banner_stale
      @option_parser.to_s
    end

    # Since we extend Object on 1.8.x, to_s is defined and thus not proxied by method_missing
    def to_s #::nodoc::
      help
    end


    # Acess the command provider list
    def commands
      @commands
    end

    def parse_to_command!
      @option_parser.order!
      if command_names.include? ::ARGV[0]
        @selected_command = ::ARGV.shift
      end
    end

    # The selected command
    def selected_command
      @selected_command
    end

    # Sets the version for the banner
    def version(version)
      @version = version
      @banner_stale = true
    end

    # List the command names
    def command_names
      @command_names ||= commands.keys.map {|k| k.to_s}
    end

    # We need some documentation to appear at the end, after all OptionParser setup
    # has occured, but before we actually start.  This method serves that purpose
    def post_setup
      if parent_opts and not (global_opts = parent_opts.global_options_help).empty?
        @option_parser.separator ''
        global_opts.split("\n").each {|line| @option_parser.separator line}
      end

      if @commands.empty? and ! @arg_documentation.empty?
        @option_parser.separator ''
        @option_parser.separator "Arguments:"
        @args.each do |arg|
          option_tag = @arg_options[arg].include?(:optional) ? ' (optional)' : ''
          @option_parser.separator "    #{arg}#{option_tag}"
          @arg_documentation[arg].each do |doc|
            @option_parser.separator "        #{doc}"
          end
        end
      end

      unless @commands.empty?
        padding = @commands.keys.map {|name| name.to_s.length}.max + 1
        @option_parser.separator ''
        @option_parser.separator "Commands:"
        @commands.each do |name,provider|
          @option_parser.separator "  #{ "%-#{padding}s" % (name.to_s+':')} #{provider.description}"
        end
      end
      @option_parser.separator ''
    end

    def extend_help_from_parent(parent_opts)
      self.parent_opts = parent_opts
      @banner_stale = true
    end

  protected

    def base_usage_line
      line = parent_opts.nil? ? "\nUsage:" : parent_opts.base_usage_line
      cmd = parent_opts && parent_opts.selected_command
      line += ' ' + (cmd || ::File.basename($0)).to_s
      if selected_command && accept_global_options?
        if parent_opts
          line += " [options for #{cmd}]"
        else
          line += " [global options]"
        end
      end
      line
    end

    def global_options_help
      msg = []
      global_option_defs = @option_defs.fetch(:global,[])
      unless global_option_defs.empty?
        cmd = parent_opts && parent_opts.selected_command
        opt_lines = [cmd.nil? ? "Global options:\n" : "Options for #{cmd}:\n"]
        width = @option_parser.summary_width
        indent = @option_parser.summary_indent
        global_option_defs.each do |opt|
          opt.summarize({},{},width,width - 1,indent) do |line|
            opt_lines << (line.index($/, -1) ? line : line + $/)
          end
        end
        msg << opt_lines.join('')
      end
      msg << parent_opts.global_options_help if parent_opts
      msg.join ("\n")
    end

    def accept_global_options?
      ! @option_defs.fetch(:global,[]).empty?
    end

  private

    # Because there is always an option for -h, if there are subcommands, they
    # need to show the option holder and Options prefix to differentiate
    # between the command option an previous options.
    def accept_options?
      @accept_options
    end

    def document_help
      @option_parser.on("-h","--help","Show command line help") do
        puts self.to_s
        exit 0
      end
      @banner_stale = true
    end

    def add_default_value_to_docstring(*args)
      default_value = nil
      option_names_from(args).each do |option|
        option = option.sub(/\A\[no-\]/,'')
        default_value = (@options[option.to_s] || @options[option.to_sym]) if default_value.nil?
      end
      if default_value.nil?
        args
      else
        args + ["(default: #{default_value})"]
      end
    end

    def option_names_from(args)
      args.select(&STRINGS_ONLY).select { |_|
        _ =~ /^\-/
      }.map { |_|
        _.gsub(/^\-+/,'').gsub(/\s.*$/,'')
      }
    end

    def option_signature(args)
      args.select(&STRINGS_ONLY).select {|s| s =~ /\A-/}.join('|')
    end


    def set_banner
      return if @user_specified_banner
      return unless @banner_stale

      new_banner = base_usage_line
      new_banner += " [options]" if (@commands.empty? or parent_opts.nil?) and accept_options?
      new_banner += " command [command options and args...]" unless @commands.empty?

      if @commands.empty? and !@args.empty?
        new_banner += " "
        new_banner += @args.map { |arg|
          if @arg_options[arg].include? :any
            "[#{arg.to_s}...]"
          elsif @arg_options[arg].include? :optional
            "[#{arg.to_s}]"
          elsif @arg_options[arg].include? :many
            "#{arg.to_s}..."
          else
            arg.to_s
          end
        }.join(' ')
      end

      new_banner += "\n\n#{@description}" if @description
      new_banner += "\n\nv#{@version}" if @version

      new_banner += "\n\nOptions:"
      @option_parser.banner=new_banner
      @banner_stale = false
    end

    def option_names(*opts_on_args,&block)
      opts_on_args.select(&STRINGS_ONLY).map { |arg|
        if arg =~ /^--\[no-\]([^-\s][^\s]*)/
          $1.to_sym
        elsif arg =~ /^--([^-\s][^\s]*)/
          $1.to_sym
        elsif arg =~ /^-([^-\s][^\s]*)/
          $1.to_sym
        else
          nil
        end
      }.reject(&:nil?).map {|name| [name,name.to_s]}.flatten
    end

    STRINGS_ONLY = lambda { |o| o.kind_of?(::String) }

  end

  InvalidProvider = Class.new(TypeError)

  OptionParser::OptionConflict = Class.new(OptionParser::ParseError)
  OptionParser::MissingRequiredOption = Class.new(OptionParser::ParseError)

end
