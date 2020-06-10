require_relative "base_integration_test"

include FileUtils

class TestRSpec < BaseIntegrationTest
  test_that "we can generate an app using RSpec instead of Test::Unit" do
    When { optparse_plus "--rspec newgem" }
    Then {
      refute Dir.exist?("newgem/test")
      assert Dir.exist?("newgem/spec")
      assert File.exist?("newgem/spec/something_spec.rb")
    }
    And {
      assert_file("newgem/newgem.gemspec", contains: /add_development_dependency\(["']rspec["']/)
    }
    And {
      stdout,_ = rake("newgem", "-T")
      assert_match(/rake spec/,stdout)
      refute_match(/rake testa/,stdout)
    }
    When {
      @stdout, _ = rake("newgem","spec")
    }
    Then {
      assert_match(/1 example,.*0 failures/,@stdout)
    }
  end
end
