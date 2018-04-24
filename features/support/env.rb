require 'aruba/cucumber'
require 'methadone/cucumber'

PROJECT_ROOT = File.join(File.dirname(__FILE__),'..','..')
ENV['PATH'] = "#{File.join(PROJECT_ROOT,'bin')}#{File::PATH_SEPARATOR}#{ENV['PATH']}"
ARUBA_DIR = File.join(%w(tmp aruba))
Before do
  @dirs = [ARUBA_DIR]
  @puts = true
  @aruba_timeout_seconds = 60
  @original_rubylib = ENV['RUBYLIB']
  @original_rubyopt = ENV['RUBYOPT']

  # We want to use, hopefully, the methadone from this codebase and not
  # the gem, so we put it in the RUBYLIB
  ENV['RUBYLIB'] = File.join(PROJECT_ROOT,'lib') + File::PATH_SEPARATOR + ENV['RUBYLIB'].to_s
end

After do
  # Put back how it was
  ENV['RUBYLIB'] = @original_rubylib
  ENV['RUBYOPT'] = @original_rubyopt
end
