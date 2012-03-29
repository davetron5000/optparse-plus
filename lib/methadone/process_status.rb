module Methadone
  # <b>Methadone Internal - treat as private</b>
  #
  # A wrapper/enhancement of Process::Status that handles coersion and expected
  # nonzero statuses
  class ProcessStatus

    # The exit status, either directly from a Process::Status or derived from a non-Int value.
    attr_reader :exitstatus

    # Create the ProcessStatus with the given status.
    #
    # status:: if this responds to #exitstatus, that method is used to extract the exit code.  If it's
    #          and Int, that is used as the exit code.  Otherwise,
    #          it's truthiness is used: 0 for truthy, 1 for falsey.
    # expected:: an Int or Array of Int representing the expected exit status, other than zero,
    #            that represent "success".
    def initialize(status,expected)
      @exitstatus = derive_exitstatus(status)
      @success = ([0] + Array(expected)).include?(@exitstatus)
    end

    # True if the exit status was a successul (i.e. expected) one.
    def success?
      @success
    end

  private

    def derive_exitstatus(status)
      status = if status.respond_to? :exitstatus
                 status.exitstatus
               else
                 status
               end
      if status.kind_of? Fixnum
        status
      elsif status
        0
      else
        1
      end
    end
  end
end
