require_relative "base_integration_test"

include FileUtils

class TestVersion < BaseIntegrationTest
  test_that "--help shows the gem version" do
    Given { methadone "newgem" }
    When { @stdout, _, = run_app "newgem", "--help" }
    Then {
      assert_match(/v\d+\.\d+\.\d+/, @stdout)
    }
  end

  test_that "--version shows the gem version" do
    Given { methadone "newgem" }
    When { @stdout, _, = run_app "newgem", "--version" }
    Then {
      assert_match(/v\d+\.\d+\.\d+/, @stdout)
    }
  end
end
