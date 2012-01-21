module Methadone
  module ExecutionStrategy
    # For RBX
    class RBXOpen_4 < Open_4
      def exception_meaning_command_not_found
        Errno::EINVAL
      end
    end
  end
end
