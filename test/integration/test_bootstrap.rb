require_relative "base_integration_test"

include FileUtils

class TestBootstrap < BaseIntegrationTest
  test_that "bootstrapping a new app generates basic boilerplate" do
    When { methadone "newgem" }
    Then {
      [
        "bin/newgem",
        "lib/newgem.rb",
        "lib/newgem/version.rb",
        "newgem.gemspec",
        "README.rdoc",
        "Rakefile",
      ].each do |file|
        assert File.exist?("newgem/#{file}"), "Expected newgem/#{file} to exist"
      end
    }
    And {
      assert_all_files_staged_in_git
    }
    When { @stdout, _ = run_app("newgem", "--help") }
    Then {
      assert_banner(@stdout, "newgem", takes_options: true, takes_arguments: false)
      assert_standard_options(@stdout)
    }
    When { @stdout, _ = rake("newgem", "-T") }
    Then {
      assert_supports_basic_rake_tasks(@stdout)
    }
    When { @stdout, _ = rake("newgem", "") }
    Then {
      assert_match(/1 tests, 1 assertions, 0 failures, 0 errors/,@stdout)
      assert_match(/1 tests, 8 assertions, 0 failures, 0 errors/,@stdout) # integration test
    }
    And {
      gemspec = File.read("newgem/newgem.gemspec")
      refute_match(/TODO/,gemspec)
      refute_match(/FIXME/,gemspec)
    }
  end

  test_that "bootstrapping a new app with a dash in its name works" do
    When { methadone "new-gem" }
    Then {
      [
        "bin/new-gem",
        "lib/new/gem.rb",
        "lib/new/gem/version.rb",
        "new-gem.gemspec",
        "README.rdoc",
        "Rakefile",
      ].each do |file|
        assert File.exist?("new-gem/#{file}"), "Expected new-gem/#{file} to exist: #{`ls -ltR new-gem`}}"
      end
    }
    When { @stdout, _ = run_app("new-gem", "--help") }
    Then {
      assert_banner(@stdout, "new-gem", takes_options: true, takes_arguments: false)
      assert_standard_options(@stdout)
    }
    When { @stdout, _ = rake("new-gem", "-T") }
    Then {
      assert_supports_basic_rake_tasks(@stdout)
    }
    When { @stdout, _ = rake("new-gem", "") }
    Then {
      assert_match(/1 tests, 1 assertions, 0 failures, 0 errors/,@stdout)
      assert_match(/1 tests, 8 assertions, 0 failures, 0 errors/,@stdout) # integration test
    }
    And {
      gemspec = File.read("new-gem/new-gem.gemspec")
      refute_match(/TODO/,gemspec)
      refute_match(/FIXME/,gemspec)
    }
  end

  test_that "won't overwrite an existing dir" do
    Given { methadone "newgem" }
    And {
      File.open("newgem/new_file.txt","w") do |file|
        file.puts "Creating a file to verify it doesn't get blown away"
      end
    }
    When { @stdout, @stderr, @status = methadone "newgem", allow_failure: true }
    Then {
      assert File.exist?("newgem/new_file.txt")
    }
    And {
      refute @status.success?
    }
    And {
      assert_match(/#{Regexp.escape("error: newgem exists, use --force to override")}/,@stderr)
    }
  end

  test_that "will overwrite an existing dir with --force" do
    Given { methadone "newgem" }
    And {
      File.open("newgem/new_file.txt","w") do |file|
        file.puts "Creating a file to verify it doesn't get blown away"
      end
    }
    When { @stdout, @stderr, @status = methadone "newgem --force", allow_failure: true }
    Then {
      refute File.exist?("newgem/new_file.txt")
    }
    And {
      assert @status.success?
    }
  end

  test_that "must supply a gem name" do
    When { _, @stderr, @status = methadone "", allow_failure: true }
    Then {
      refute @status.success?
    }
    And {
      assert_match(/\'app_name\' is required/,@stderr)
    }
  end

  def assert_standard_options(stdout)
    assert_option(stdout,"--version")
    assert_option(stdout,"--help")
    assert_option(stdout,"--log-level")
  end

  def assert_supports_basic_rake_tasks(stdout)
    [
      :clean,
      :clobber,
      :clobber_rdoc,
      :rdoc,
      :release,
      :rerdoc,
      :test,
      :install,
      :build,
    ].each do |rake_task|
      assert_match(/rake #{rake_task}/,stdout)
    end
  end

  def assert_all_files_staged_in_git
    stdout, _, __ = run_in_gem("newgem", "git", "ls-files --others --deleted")
    assert_match(/\A\Z/, stdout)
  end
end
