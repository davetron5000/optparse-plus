require 'base_test'
require 'mocha/setup'

# Defined by JRuby, but this test must pass on any Ruby
class NativeException
end

module ExecutionStrategy
  class TestJVM < BaseTest
    include Methadone::ExecutionStrategy

    test_that "run_command proxies to Open3.capture3" do
      Given {
        @process = mock('java.lang.Process')
        @runtime = mock('java.lang.Runtime')
        @command = "ls"
        @stdout = any_string
        @stderr = any_string
        @exitstatus = any_int :min => 1, :max => 127
      }
      When the_test_runs
      Then {
        expects_lang = mock()
        JVM.any_instance.expects(:java).returns(expects_lang)
        expects_Runtime = mock()
        expects_lang.expects(:lang).returns(expects_Runtime)
        runtime_klass = mock()
        expects_Runtime.expects(:Runtime).returns(runtime_klass)
        runtime_klass.expects(:get_runtime).returns(@runtime)
        @runtime.expects(:exec).with(@command).returns(@process)

        stdin = mock()
        @process.expects(:get_output_stream).returns(stdin)
        stdin.expects(:close)

        stdout_input_stream = mock('InputStream')
        @process.expects(:get_input_stream).returns(stdout_input_stream)
        stdout_input_stream.expects(:read).times(2).returns(
          @stdout,
          -1)

        stderr_input_stream = mock('InputStream')
        @process.expects(:get_error_stream).returns(stderr_input_stream)
        stderr_input_stream.expects(:read).times(2).returns(
          @stderr,
          -1)

        @process.expects(:wait_for).returns(@exitstatus)
      }

      Given new_jvm_strategy
      When {
        @results = @strategy.run_command(@command)
      }
      Then {
        @results[0].should be == @stdout
        @results[1].should be == @stderr
        @results[2].exitstatus.should be == @exitstatus
      }
    end

    test_that "exception_meaning_command_not_found returns NativeException" do
      Given new_jvm_strategy
      When {
        @klass = @strategy.exception_meaning_command_not_found
      }
      Then {
        @klass.should be == NativeException
      }
    end

  private
    def new_jvm_strategy
      lambda { @strategy = JVM.new }
    end
  end
end
