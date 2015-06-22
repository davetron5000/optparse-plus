require 'base_test'
require 'methadone'
require 'stringio'
require 'fileutils'

class TestMulti < BaseTest
  include Methadone::Main
  include Methadone::CLILogging

  module Commands
    class Walk
      include Methadone::Main
      include Methadone::CLILogging
      main do |distance|
        puts "walk called"
      end
      options[:direction] = 0
      description "moves slowly for a given distance"
      on '-s', '--silly-walk'
      on '-d', '--direction DIRECTION', Integer, "Compass cardinal direction"
      arg "distance", "How far to walk"

    end
    class Run
      include Methadone::Main
      include Methadone::CLILogging
      main do |distance, duty_cycle|
        puts "run called"
      end
      options[:direction] = 0
      description "moves quickly for a given distance"
      on '-s', '--silly-walk'
      on '-d', '--direction DIRECTION', Integer, "Compass cardinal direction"
      arg "distance", "How far to run"
      arg "duty_cycle", "Percent of time spent running (default: 100)", :optional
    end
    class Greet
      include Methadone::Main

      options[:lang] = 'es'

      main do
        msg = case options[:lang]
        when 'en'
          'Hello'
        when 'fr'
          'Bonjour'
        when 'es'
          'Hola'
        else
          '????'
        end

        msg = msg.upcase if options[:yell]
        puts msg
      end
    end

    class Say
      include Methadone::Main
      on '--yell', "Be loud", :global
      command 'greeting' => ::TestMulti::Commands::Greet
    end
  end

  def setup
    @original_argv = ARGV.clone
    ARGV.clear
    @old_stdout = $stdout
    $stdout = StringIO.new
    @logged = StringIO.new
    @orig_logger = logger
    @custom_logger = Logger.new(@logged)
    change_logger @custom_logger

    @original_home = ENV['HOME']
    fake_home = '/tmp/fake-home'
    FileUtils.rm_rf(fake_home)
    FileUtils.mkdir(fake_home)
    ENV['HOME'] = fake_home
  end

  def teardown
    @commands = nil
    change_logger @orig_logger
    set_argv @original_argv
    ENV.delete('DEBUG')
    ENV.delete('APP_OPTS')
    $stdout = @old_stdout
    ENV['HOME'] = @original_home
  end

  test_that "commands can be specified" do
    When {
      command "walk" => Commands::Walk
    }
    Then number_of_commands_should_be(1)
    Then commands_should_include("walk")
    Then {
      provider_for_command("walk").should be Commands::Walk
    }
  end

  test_that "command providers must accept go! message" do
    Given {
      module Commands
        class WontWork
        end
      end
    }
    When {
      @error = nil
      begin
        command "trythis" => Commands::WontWork
      rescue Exception => error
        @error = error
      end
    }
    Then number_of_commands_should_be(0)
    Then {
      @error.should be_a_kind_of(::Methadone::InvalidProvider)
    }
  end

  test_that "command is detected in the arguments" do
    Given {
      main do
      end

      command "walk" => Commands::Walk
      set_argv %w(walk 10)
    }
    When run_go_safely
    Then {
      opts.selected_command.should eq('walk')
    }
  end

  test_that "command in the arguments causes the right command to be called" do
    Given app_has_subcommands('walk','run')
    And {
      version '1.2.3'
      set_argv %w(walk 10)
    }
    When run_go_safely
    Then {
      opts.command_names.should include('walk')
      opts.command_names.should include('run')
      $stdout.string.should match(/walk called/)
    }
    And number_of_commands_should_be(2)
  end

  test_that "help is displayed if no command on command line" do
    Given app_has_subcommands('walk','run')
    And {
      @main_called = false
      main do
        @main_called = true
        puts 'main called'
      end
    }
    When run_go_safely
    Then main_should_not_be_called
    And help_shown
    And {
      assert_logged_at_error("You must specify a command")
    }
  end

  test_that "app with subcommands list subcommands in help" do
    Given app_has_subcommands('walk','run')
    When {
      setup_defaults
      opts.post_setup
    }
    Then {
      opts.to_s.should match /(?m)Commands:\n.*walk: moves slowly/
      opts.to_s.should match /(?m)Commands:\n.*run:  moves quickly/
    }
    And {
      opts.to_s.should match /Usage:.*command \[command options and args...\]/
    }
  end

  test_that "app without subcommands do not list command prefix in help" do
    Given {
      main do
      end
      on '--switch'
      on '--flag FOO'
      arg 'must_have'
      arg 'optionals', :any
    }
    When {
      setup_defaults
      opts.post_setup
    }
    Then {
      opts.to_s.should_not match /Commands:/m
    }
  end

  test_that "subcommand can get its own help" do
    Given app_has_subcommands('walk','run')
    And {
      version '1.2.3'
      set_argv %w(walk -h)
    }
    When run_go_safely
    Then {
      $stdout.string.should match /Usage: #{::File.basename($0)} walk \[options\] distance/
    }
  end

  someday_test_that "rc_file can specify defaults for each subcommand" do
  end

  test_that "subcommand help shows global options from parent" do
    Given app_has_subcommands('walk','run')
    And {
      version '1.2.3'
      set_argv %w(walk -h)
      on '-w','--wow', :global, "This is a global option"
    }
    When run_go_safely
    Then {
      $stdout.string.should match /Usage: #{::File.basename($0)} \[global options\] walk \[options\] distance/
      $stdout.string.should match /(?m)Global options:\n.*-w, --wow *This is a global option/
      $stdout.string.should_not match /(?m)Global options:\n.*-v, --version/
    }
  end


  test_that "subcommands have access to global options" do
    Given app_has_subcommands('greet')
    And {
      options[:lang] = 'en'
      on '-l', '--lang LANG','Set the language', :global
      set_argv %w(-l fr greet)
    }
    When run_go_safely
    Then {
      $stdout.string.should match /Bonjour/
      $stdout.string.should_not match /Hello/
      $stdout.string.should_not match /Hola/
      $stdout.string.should_not match /\?\?\?\?/
    }
  end

  test_that "subcommands of subcommands help shows parents global options" do
    Given app_is_three_layers_deep_with_middle_layer_having_global_options
    And {
      set_argv %w(say --yell greeting)
    }
    When run_go_safely
    Then {
      cmd_opts = opts.commands['say'].opts.commands['greeting'].opts
      cmd_opts.to_s.should match /say \[options [f]or say\] greeting/
      cmd_opts.to_s.should match /(?m)Options [f]or say:\n.*--yell *Be loud/
      cmd_opts.to_s.should_not match /\[global options\]/
      cmd_opts.to_s.should_not match /Global options:/
      $stdout.string.should match /HOLA/
    }
  end

  test_that "subcommands of subcommands help shows parents global options and base global options" do
    Given app_is_three_layers_deep_with_middle_layer_having_global_options
    And {
      on '-l', '--lang LANG','Set the language', :global
      set_argv %w(-l en say --yell greeting)
    }
    When run_go_safely
    Then {
      cmd_opts = opts.commands['say'].opts.commands['greeting'].opts
      cmd_opts.to_s.should match /\[global options\] say \[options [f]or say\] greeting/
      cmd_opts.to_s.should match /(?m)Options [f]or say:\n.*--yell *Be loud/
      cmd_opts.to_s.should match /(?m)Global options:\n.*-l, --lang LANG *Set the language/
      $stdout.string.should match /HELLO/
    }
  end

private

  def commands_should_include(cmd)
    proc { opts.commands.keys.should include(cmd) }
  end

  def number_of_commands_should_be(num)
    proc { opts.commands.keys.length.should be(num)}
  end

  def provider_for_command(cmd)
    opts.commands[cmd]
  end

  def app_has_subcommands(*args)
    proc {
      args.each do |cmd|
        command cmd => get_const("TestMulti::Commands::#{cmd.capitalize}")
      end
    }
  end

  def app_is_three_layers_deep_with_middle_layer_having_global_options
    proc {
      # Requires special resetting to ensure proper behaviour
      reset!
      command 'say' => get_const("TestMulti::Commands::Say")
      opts.commands['say'].instance_variable_get(:@options).delete_if {|k,v| true}
      opts.commands['say'].opts.commands['greeting'].instance_variable_get(:@options).delete_if {|k,v| true}
      opts.commands['say'].opts.commands['greeting'].instance_variable_get(:@options)[:lang] = 'es'
    }
  end


  def help_shown
    proc {assert $stdout.string.include?(opts.to_s),"Expected #{$stdout.string} to contain #{opts.to_s}"}
  end

  def app_to_use_rc_file
    lambda {
      @switch = nil
      @flag = nil
      @args = nil
      main do |*args|
        @switch = options[:switch]
        @flag = options[:flag]
        @args = args
      end

      defaults_from_config_file '.my_app.rc'

      on('--switch','Some Switch')
      on('--flag FOO','Some Flag')
    }
  end

  def main_that_exits(exit_status)
    proc { main { exit_status } }
  end

  def app_to_use_environment
    lambda {
      @switch = nil
      @flag = nil
      @args = nil
      main do |*args|
        @switch = options[:switch]
        @flag = options[:flag]
        @args = args
      end

      defaults_from_env_var 'APP_OPTS'

      on('--switch','Some Switch')
      on('--flag FOO','Some Flag')
    }
  end

  def main_should_not_be_called
    Proc.new { assert !@main_called,"Main block was called?!" }
  end

  def main_shouldve_been_called
    Proc.new { assert @main_called,"Main block wasn't called?!" }
  end

  def run_go_safely
    Proc.new { safe_go! }
  end

  # Calls go!, but traps the exit
  def safe_go!
    go!
  rescue SystemExit
  end

  def run_go!; proc { go! }; end

  def assert_logged_at_error(expected_message)
    @logged.string.should include expected_message
  end

  def assert_exits(exit_code,message='',&block)
    block.call
    fail "Expected an exit of #{exit_code}, but we didn't even exit!"
  rescue SystemExit => ex
    assert_equal exit_code,ex.status,@logged.string
  end

  def set_argv(args)
    ARGV.clear
    args.each { |arg| ARGV << arg }
  end

  def get_const(class_name)
    unless /\A(?:::)?([A-Z]\w*(?:::[A-Z]\w*)*)\z/ =~ class_name
      raise NameError, "#{class_name.inspect} is not a valid constant name!"
    end

    Object.module_eval("::#{$1}", __FILE__, __LINE__)
  end

end
