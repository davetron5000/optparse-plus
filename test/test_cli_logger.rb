require 'base_test'
require 'methadone'
require 'stringio'

class TestCLILogger < BaseTest
  include Methadone
  
  def setup
    @real_stderr = $stderr
    @real_stdout = $stdout
    $stderr = StringIO.new
    $stdout = StringIO.new
  end

  def teardown
    $stderr = @real_stderr
    $stdout = @real_stdout
  end

  test "logger sends everything to stdout, and warns, errors, and fatals to stderr" do
    logger = CLILogger.new
    logger.formatter = proc { |severity,datetime,progname,msg|
      msg + "\n"
    }
    logger.debug("debug")
    logger.info("info")
    logger.warn("warn")
    logger.error("error")
    logger.fatal("fatal")

    $stdout.string.should == "debug\ninfo\nwarn\nerror\nfatal\n"
    $stderr.string.should == "warn\nerror\nfatal\n"
  end

end
