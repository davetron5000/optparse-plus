module Methadone
  module ExecutionStrategy
    # <b>Methadone Internal - treat as private</b>
    #
    # ExecutionStrategy for non-modern Rubies that must rely on
    # Open4 to get access to the standard output AND error.
    class Open_4 < MRI
      def run_command(command)
        pid, stdin_io, stdout_io, stderr_io =
          case command
          when String then Open4::popen4(command)
          else Open4::popen4(*command)
          end
        stdin_io.close
        stdout = stdout_io.read
        stderr = stderr_io.read
        _ , status = Process::waitpid2(pid)
        [stdout.chomp,stderr.chomp,status]
      end
    end
  end
end
