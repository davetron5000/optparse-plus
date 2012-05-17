module Methadone
  module ExecutionStrategy
    # <b>Methadone Internal - treat as private</b>
    #
    # Methadone::ExecutionStrategy for the JVM that uses JVM classes to run the command and get its results.
    class JVM < Base
      def run_command(command)
        process = case command
                  when String then
                    java.lang.Runtime.get_runtime.exec(command)
                  else
                    java.lang.Runtime.get_runtime.exec(*command)
                  end
        process.get_output_stream.close
        stdout = input_stream_to_string(process.get_input_stream)
        stderr = input_stream_to_string(process.get_error_stream)
        exitstatus = process.wait_for
        [stdout.chomp,stderr.chomp,OpenStruct.new(:exitstatus => exitstatus)]
      end

      def exception_meaning_command_not_found
        NativeException
      end

    private
      def input_stream_to_string(is)
        ''.tap do |string|
          ch = is.read
          while ch != -1
            string << ch
            ch = is.read
          end
        end
      end
    end
  end
end
