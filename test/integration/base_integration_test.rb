require "optparse_plus/test/base_integration_test"
require "clean_test/test_case"

class BaseIntegrationTest < OptparsePlus::BaseIntegrationTest
  include Clean::Test::GivenWhenThen
  include Clean::Test::TestThat
  include Clean::Test::Any
  def setup
    root = (Pathname(__FILE__).dirname / ".." / "..").expand_path
    ENV["PATH"] = (root / "bin").to_s + File::PATH_SEPARATOR + ENV["PATH"]
    ENV["RUBYLIB"] = (root / "lib").to_s + File::PATH_SEPARATOR + ENV["RUBYLIB"]
    @pwd = pwd
    @tmdir = Dir.mktmpdir
    chdir @tmdir
  end

  def teardown
    chdir @pwd
    rm_rf @tmdir
  end

private

  def optparse_plus(args, allow_failure: false)
    command = "optparse_plus #{args}"
    stdout, stderr, status = Open3.capture3(command)
    if !status.success? && !allow_failure
      raise "'#{command}' failed: #{status.inspect}\n\nSTDOUT:\n\n#{stdout}\n\nSTDERR:\n\n#{stderr}\nEND"
    end
    [ stdout, stderr, status ]
  end

  def run_app(gemname,args="")
    run_in_gem(gemname, "bin/#{gemname}", args)
  end

  # Runs rake inside the app for an integration test, returning stdout and stderr as strings
  def rake(gemname,args="")
    run_in_gem(gemname, "rake", args)
  end

  # Runs an arbitrary command inside the gem, returning stdout and stderr as strings.
  def run_in_gem(gemname, command, args)
    stdout = nil
    stderr = nil
    original_rubylib = ENV["RUBYLIB"]
    chdir gemname do
      ENV["RUBYLIB"] = "lib" + File::PATH_SEPARATOR + original_rubylib
      stdout, stderr, result = Open3.capture3("#{command} #{args}")
      unless result.success?
        raise "#{stdout}\n#{stderr}"
      end
    end
    [ stdout, stderr ]
  ensure
    ENV["RUBYLIB"] = original_rubylib
  end


end
