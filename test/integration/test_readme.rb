require_relative "base_integration_test"
class TestReadme < BaseIntegrationTest
  test_that "a reasonable README is created" do
    When {
      methadone "newgem --readme"
    }
    Then {
      assert File.exist?("newgem/README.rdoc")
    }
    And {
      readmes = Dir["newgem/README*"].to_a
      assert_equal 1, readmes.size,"Found more than one README: #{readmes.inspect}"
    }
    And {
      rakefile_contents = File.read("newgem/Rakefile")
      assert_match(/README.rdoc/,rakefile_contents)
      assert_match(/rd.main = ["']README.rdoc["']/,rakefile_contents)
    }
    And {
      assert_file("newgem/README.rdoc",
                  contains: [
                    /newgem/,
                    /Author::  YOUR NAME \(YOUR EMAIL\)/,
                    /\* \{Source on Github\}\[LINK TO GITHUB\]/,
                    /RDoc\[LINK TO RDOC.INFO\]/,
                    /^== Install/,
                    /^== Examples/,
                    /^== Contributing/,
      ])
    }
  end

  test_that "a readme is created by default" do
    When {
      methadone "newgem"
    }
    Then {
      assert File.exist?("newgem/README.rdoc")
    }
  end

  test_that "we can omit a README" do
    When {
      methadone "--no-readme newgem"
    }
    Then {
      refute File.exist?("newgem/README.rdoc")
    }
    And {
      refute_match(/README/,File.read("newgem/Rakefile"))
    }
  end
end
