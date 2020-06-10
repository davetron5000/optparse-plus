module OptparsePlus
  module ExecutionStrategy
    # <b>OptparsePlus Internal - treat as private</b>
    #
    # Implementation for modern Rubies that uses the built-in Open3 library
    class Open_3 < MRI
      def run_command(command)
        stdout,stderr,status = case command
                               when String then Open3.capture3(command)
                               else Open3.capture3(*command)
                               end
        [stdout.chomp,stderr.chomp,status]
      end
    end
  end
end
