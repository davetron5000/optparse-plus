require_relative "base_integration_test"

include FileUtils

class TestCli < BaseIntegrationTest
  test_that "optparse_plus CLI is properly documented" do
    When { @stdout, _, __ = optparse_plus "--help" }
    Then {
      assert_banner(@stdout, "optparse_plus", takes_options: true, takes_arguments: { app_name: :required })
    }
    And {
      assert_option(@stdout, "--force")
      assert_option(@stdout, "--[no-]readme")
      assert_option(@stdout, "-l", "--license")
      assert_option(@stdout, "--log-level")
    }
    And {
      assert_oneline_summary(@stdout)
    }
  end
end
