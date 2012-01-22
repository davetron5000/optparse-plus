module Methadone
  module ExecutionStrategy
    # Base strategy for MRI rubies.
    class MRI < Base
      def run_command(command)
        raise "subclass must implement"
      end

      def exception_meaning_command_not_found
        Errno::ENOENT
      end
    end
  end
end
