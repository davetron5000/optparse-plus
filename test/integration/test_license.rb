require_relative "base_integration_test"

include FileUtils

class TestLicense < BaseIntegrationTest
  test_that "omitting a license generates a warning" do
    When { _, @stderr, __ = methadone "newgem" }
    Then {
      assert_match(/warning: your app has no license/,@stderr)
    }
  end

  test_that "explicitly omitting a license does not generate a warning" do
    When { _, @stderr, __ = methadone "newgem -l NONE" }
    Then {
      refute_match(/warning: your app has no license/,@stderr)
    }
  end

  [
    "apache",
    "mit",
    "gplv2",
    "gplv3",
  ].each do |license|
    test_that "the #{license} license can be included" do
      When { methadone "newgem -l #{license}" }
      Then {
        assert File.exist?("newgem/LICENSE.txt")
      }
      And {
        assert_file("newgem/newgem.gemspec", contains: /#{license.upcase}/)
      }
    end
  end

  test_that "a custom license can be included" do
    When { methadone "newgem -l custom" }
    Then {
      assert File.exist?("newgem/LICENSE.txt")
    }
    And {
      assert_equal "", File.read("newgem/LICENSE.txt").strip
    }
  end

  test_that "a non-custom non-supported license causes an error" do
    When { _, @stderr, @result = methadone "newgem -l foobar", allow_failure: true }
    Then {
      refute @result.success?
    }
    And {
      assert_match(/invalid argument: -l foobar/,@stderr)
    }
  end
end
