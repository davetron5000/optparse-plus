require 'base_test'

module ExecutionStrategy
  class TestMRI < BaseTest
    include Methadone::ExecutionStrategy

    test_that "run_command isn't implemented" do
      Given new_mri_strategy
      When {
        @code = lambda { @strategy.run_command("ls") }
      }
      Then {
        assert_raises(RuntimeError,&@code)
      }
    end

    test_that "exception_meaning_command_not_found returns Errno::ENOENT" do
      Given new_mri_strategy
      When {
        @klass = @strategy.exception_meaning_command_not_found
      }
      Then {
        @klass.should == Errno::ENOENT
      }
    end

  private
    def new_mri_strategy
      lambda { @strategy = MRI.new }
    end
  end
end
