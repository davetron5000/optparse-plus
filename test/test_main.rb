require 'base_test'
require 'methadone'
require 'stringio'

class TestMain < BaseTest
  include Methadone::Main

  def setup
    @logged = []
    @original_argv = ARGV.clone
    ARGV.clear
  end

  # Override error so we can capture what's being logged at this level
  def error(string)
    @logged << string
  end

  def teardown
    set_argv @original_argv
  end

  test_that "my main block gets called by run and has access to CLILogging" do
    Given {
      @called = false
      main do
        begin
          debug "debug"
          info "info"
          warn "warn"
          error "error"
          fatal "fatal"
          @called = true
        rescue => ex
          puts ex.message
        end
      end
    }
    When run_go_safely
    Then main_shouldve_been_called
  end

  test_that "my main block gets the command-line parameters" do
    Given {
      @params = []
      main do |param1,param2,param3|
        @params << param1
        @params << param2
        @params << param3
      end
      set_argv %w(one two three)
    }
    When run_go_safely
    Then {
      assert_equal %w(one two three),@params
    }
  end

  test_that "my main block can freely ignore arguments given" do
    Given {
      @called = false
      main do
        @called = true
      end
      set_argv %w(one two three)
    }
    When run_go_safely
    Then main_shouldve_been_called
  end

  test_that "my main block can ask for arguments that it might not receive" do
    Given {
      @params = []
      main do |param1,param2,param3|
        @params << param1
        @params << param2
        @params << param3
      end
      set_argv %w(one two)
    }
    When run_go_safely
    Then {
      assert_equal ['one','two',nil],@params
    }
  end

  test_that "go exits zero when main evaluates to nil or some other non number" do
    [nil,'some string',Object.new,[],4.5].each do |non_number|
      Given main_that_exits non_number
      Then {
        assert_exits(0,"for value #{non_number}") { When run_go!  }
      }
    end
  end

  def run_go!; proc { go! }; end

  test_that "go exits with the numeric value that main evaluated to" do
    [0,1,2,3].each do |exit_status|
      Given main_that_exits exit_status
      Then {
        assert_exits(exit_status) { When run_go! }
      }
    end
  end

  def main_that_exits(exit_status)
    proc { main { exit_status } }
  end

  test_that "go exits with 70, which is the Linux sysexits.h code for this sort of thing, if there's an exception" do
    Given {
      main do
        raise "oh noes"
      end
    }
    Then {
      assert_exits(70) { When run_go! }
      assert_logged_at_error "oh noes"
    }
  end

  test_that "go exits with the exit status included in the special-purpose excepiton" do
    Given {
      main do
        raise Methadone::Error.new(4,"oh noes")
      end
    }
    Then {
      assert_exits(4) { When run_go! }
      assert_logged_at_error "oh noes"
    }
  end

  test_that "can exit with a specific status by using the helper method instead of making a new exception" do
    Given {
      main do
        exit_now!(4,"oh noes")
      end
    }
    Then {
      assert_exits(4) { When run_go! }
      assert_logged_at_error "oh noes"
    }
  end

  test_that "opts allows us to more expediently set up OptionParser" do
    Given {
      @switch = nil
      @flag = nil
      main do
        @switch = options[:switch]
        @flag = options[:flag]
      end

      opts.on("--switch") { options[:switch] = true }
      opts.on("--flag FLAG") { |value| options[:flag] = value }

      set_argv %w(--switch --flag value)
    }

    When run_go_safely

    Then {
      assert @switch
      assert_equal 'value',@flag
    }
  end

  test_that "when the command line is invalid, we exit with 64" do
    Given {
      main do
      end

      opts.on("--switch") { options[:switch] = true }
      opts.on("--flag FLAG") { |value| options[:flag] = value }

      set_argv %w(--invalid --flag value)
    }

    Then {
      assert_exits(64) { When run_go! }
    }
  end

  test_that "omitting the block to opts simply sets the value in the options hash and returns itself" do
    Given {
      @switch = nil
      @negatable = nil
      @flag = nil
      @f = nil
      @other = nil
      @some_other = nil
      main do
        @switch = options[:switch]
        @flag = options[:flag]
        @f = options[:f]
        @negatable = options[:negatable]
        @other = options[:other]
        @some_other = options[:some_other]
      end

      on("--switch")
      on("--[no-]negatable")
      on("--flag FLAG","-f","Some documentation string")
      on("--other") do 
        options[:some_other] = true
      end

      set_argv %w(--switch --flag value --negatable --other)
    }

    When run_go_safely

    Then {
      assert @switch
      assert @some_other
      refute @other
      assert_equal 'value',@flag
      assert_equal 'value',@f,opts.to_s
      assert_match /Some documentation string/,opts.to_s
    }
  end

  test_that "without specifying options, [options] doesn't show up in our banner" do
    Given {
      main {}
    }

    Then {
      refute_match /\[options\]/,opts.banner
    }
  end

  test_that "when specifying an option, [options] shows up in the banner" do
    Given {
      main {}
      on("-s")
    }

    Then {
      assert_match /\[options\]/,opts.banner
    }

  end

  test_that "I can specify which arguments my app takes and if they are required" do
    Given {
      main {}

      arg :db_name
      arg :user, :required
      arg :password, :optional
    }

    Then {
      assert_match /db_name user \[password\]$/,opts.banner
    }
  end

  test_that "I can specify which arguments my app takes and if they are singular or plural" do
    Given {
      main {}

      arg :db_name
      arg :user, :required, :one
      arg :tables, :many
    }

    Then {
      assert_match /db_name user tables...$/,opts.banner
    }
  end

  test_that "I can specify which arguments my app takes and if they are singular or optional plural" do
    Given {
      main {}
      
      arg :db_name
      arg :user, :required, :one
      arg :tables, :any
    }

    Then {
      assert_match /db_name user \[tables...\]$/,opts.banner
    }
  end

  test_that "I can set a description for my app" do
    Given {
      main {}
      description "An app of total awesome"

    }
    Then {
      assert_match /^An app of total awesome$/,opts.banner
    }
  end

  test_that "when I override the banner, we don't automatically do anything" do
    Given {
      main {}
      opts.banner = "FOOBAR"

      on("-s")
    }

    Then {
      assert_equal "FOOBAR",opts.banner
    }
  end

  test_that "when I say an argument is required and its omitted, I get an error" do
    Given {
      main {}
      arg :foo
      arg :bar

      set_argv %w(blah)
    }

    Then {
      assert_exits(64) { When run_go! }
      assert_logged_at_error("parse error: 'bar' is required")
    }
  end

  test_that "when I say an argument is many and its omitted, I get an error" do
    Given {
      main {}
      arg :foo
      arg :bar, :many

      set_argv %w(blah)
    }

    Then {
      assert_exits(64) { When run_go! }
      assert_logged_at_error("parse error: at least one 'bar' is required")
    }
  end

  private

  def main_shouldve_been_called
    Proc.new { assert @called,"Main block wasn't called?!" }
  end
  
  def run_go_safely
    Proc.new { safe_go! }
  end

  # Calls go!, but traps the exit
  def safe_go!
    go!
  rescue SystemExit
  end

  def assert_logged_at_error(expected_message)
    assert @logged.include?(expected_message),"#{@logged} didn't include '#{expected_message}'"
  end

  def assert_exits(exit_code,message='',&block)
    block.call
    fail "Expected an exit of #{exit_code}, but we didn't even exit!"
  rescue SystemExit => ex
    assert_equal exit_code,ex.status,message
  end

  def set_argv(args)
    ARGV.clear
    args.each { |arg| ARGV << arg }
  end
end
