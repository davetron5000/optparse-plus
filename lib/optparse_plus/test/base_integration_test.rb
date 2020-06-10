require "test/unit"
require "fileutils"
require "pathname"
require "tmpdir"
require "open3"

require_relative "integration_test_assertions"

# Clean test should be setting this
$FOR_TESTING_ONLY_SKIP_STDERR = false

module OptparsePlus
end
class OptparsePlus::BaseIntegrationTest < Test::Unit::TestCase
  include FileUtils
  include OptparsePlus::IntegrationTestAssertions

  # Run your app, capturing stdout, stderr, and process status.
  # app_name:: Your bin name, without `bin/`
  # args:: CLI args as a string
  # allow_failure:: if true, this will return even if the app invocation fails.  If false (the default), blows up if things go
  # wrong.
  def run_app(app_name, args, allow_failure: false)
    command = "bin/#{app_name} #{args}"
    stdout,stderr,results = Open3.capture3(command)
    if @allow_failure && !results.success?
      raise "'#{command}' failed!: #{results.inspect}\n\nSTDOUT {\n#{stdout}\n} STDERR {\n#{stderr}\n} END"
    end
    [stdout,stderr,results]
  end
end
