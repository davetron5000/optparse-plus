require "test/unit"
require "clean_test/test_case"
require "fileutils"
require "pathname"
require "tmpdir"
require "open3"

$FOR_TESTING_ONLY_SKIP_STDERR = false

class BaseIntegrationTest < Clean::Test::TestCase
  include FileUtils

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

  def methadone(args, allow_failure: false)
    command = "methadone #{args}"
    stdout, stderr, status = Open3.capture3(command)
    if !status.success? && !allow_failure
      raise "'#{command}' failed: #{status.inspect}\n\nSTDOUT:\n\n#{stdout}\n\nSTDERR:\n\n#{stderr}\nEND"
    end
    [ stdout, stderr, status ]
  end

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

  def run_app(gemname,args="")
    run_in_gem(gemname, "bin/#{gemname}", args)
  end

  def rake(gemname,args="")
    run_in_gem(gemname, "rake", args)
  end

  def assert_file(filename, contains:)
    contents = File.read(filename)
    Array(contains).each do |regexp|
      assert_match(regexp,contents,"Expected #{filename} to contain #{regexp}")
    end
  end
end
