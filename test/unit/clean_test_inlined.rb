module CleanTestInlined
  def any_string
    [
      "some string that does not matter",
      "some other string",
      "still another string",
      "some string"
    ].sample
  end
  def any_sentence
    any_string
  end
  def any_int
    rand(1000)
  end

  def Given(existing_block=nil,*other_args,&block)
    if existing_block.nil?
      block.call(*other_args)
      block
    else
      if existing_block.kind_of?(Symbol)
        existing_block = method(existing_block)
      end
      existing_block.call(*other_args)
      existing_block
    end
  end

  def test_test_runs
    lambda {}
  end

  # Public: Execute the code under test.  Behavior identical to Given
  alias :When :Given
  # Public: Assert the results of the test. Behavior identical to Given
  alias :Then :Given
  # Public: Extend a Given/When/Then when using method or lambda form. Behavior identical to Given
  alias :And :Given
  # Public: Extend a Given/When/Then when using method or lambda form. Behavior identical to Given
  alias :But :Given

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def test_that(description=nil,&block)
      raise "You must provide a block" if block.nil?
      test_name = "test_#{description.gsub(/\s+/,'_')}".to_sym
      defined = instance_method(test_name) rescue false
      raise "#{test_name} is already defined in #{self}" if defined
      define_method(test_name, &block)
    end
  end
end
