Feature: Bootstrap a new command-line app
  As an awesome developer who wants to make a command-line app
  I should be able to use methadone to bootstrap it
  And get all kinds of cool things

  Background:
    Given the directory "tmp/newgem" does not exist
    And the directory "tmp/new-gem" does not exist

  Scenario: Bootstrap a new app from scratch
    When I successfully run `methadone tmp/newgem`
    Then the following directories should exist:
      |tmp/newgem                           |
      |tmp/newgem/bin                       |
      |tmp/newgem/lib                       |
      |tmp/newgem/lib/newgem                |
      |tmp/newgem/test                      |
      |tmp/newgem/features                  |
      |tmp/newgem/features/support          |
      |tmp/newgem/features/step_definitions |
    Then the following directories should not exist:
      |tmp/newgem/spec |
    And the following files should exist:
      |tmp/newgem/newgem.gemspec                            |
      |tmp/newgem/Rakefile                                  |
      |tmp/newgem/.gitignore                                |
      |tmp/newgem/Gemfile                                   |
      |tmp/newgem/bin/newgem                                |
      |tmp/newgem/features/newgem.feature                   |
      |tmp/newgem/features/support/env.rb                   |
      |tmp/newgem/features/step_definitions/newgem_steps.rb |
      |tmp/newgem/test/tc_something.rb                      |
    And the file "tmp/newgem/.gitignore" should match /results.html/
    And the file "tmp/newgem/.gitignore" should match /html/
    And the file "tmp/newgem/.gitignore" should match /pkg/
    And the file "tmp/newgem/.gitignore" should match /.DS_Store/
    And the file "tmp/newgem/newgem.gemspec" should match /add_development_dependency\('aruba'/
    And the file "tmp/newgem/newgem.gemspec" should match /add_development_dependency\('rdoc'/
    And the file "tmp/newgem/newgem.gemspec" should match /add_development_dependency\('rake'/
    And the file "tmp/newgem/newgem.gemspec" should match /add_dependency\('methadone'/
    And the file "tmp/newgem/newgem.gemspec" should use the same block variable throughout
    Given I cd to "tmp/newgem"
    And my app's name is "newgem"
    When I successfully run `bin/newgem --help` with "lib" in the library path
    Then the banner should be present
    And the banner should document that this app takes options
    And the following options should be documented:
      |--version|
      |--help|
      |--log-level|
    And the banner should document that this app takes no arguments
    When I successfully run `rake -T -I../../lib`
    Then the output should match /rake clean/
    Then the output should match /rake clobber/
    Then the output should match /rake clobber_rdoc/
    Then the output should match /rake features/
    Then the output should match /rake rdoc/
    Then the output should match /rake release/
    Then the output should match /rake rerdoc/
    Then the output should match /rake test/
    And the output should match /rake install       # Build and install newgem-0.0.1.gem into system gems/
    And the output should match /rake build         # Build newgem-0.0.1.gem into the pkg directory/
    When I run `rake -I../../../../lib`
    Then the exit status should be 0
    And the output should match /1 tests, 1 assertions, 0 failures, 0 errors/
    And the output should contain:
    """
    1 scenario (1 passed)
    6 steps (6 passed)
    """

  Scenario Outline: Bootstrap a new app with a dash is OK
    Given I successfully run `methadone tmp/new-gem`
    And I cd to "tmp/new-gem"
    And my app's name is "new-gem"
    When I successfully run `bin/new-gem <help>` with "lib" in the library path
    Then the banner should be present
    And the banner should document that this app takes options
    And the following options should be documented:
      |--version|
      |--log-level|
    And the banner should document that this app takes no arguments
    When I run `rake -I../../../../lib`
    Then the exit status should be 0
    And the output should match /1 tests, 1 assertions, 0 failures, 0 errors/
    And the output should contain:
    """
    1 scenario (1 passed)
    6 steps (6 passed)
    """
    Examples:
      | help      |
      | -h        |
      | --help    |
      | --version |

  Scenario: Version flag can be used to only show the app version
    Given I successfully run `methadone tmp/new-gem`
    And "bin/new-gem" has configured version to show only the version and not help
    And I cd to "tmp/new-gem"
    And my app's name is "new-gem"
    When I successfully run `bin/new-gem --version` with "lib" in the library path
    Then the output should contain:
    """
    new-gem version 0.0.1
    """

  Scenario: Version flag can be used to only show the app version with a custom format
    Given I successfully run `methadone tmp/new-gem`
    And "bin/new-gem" has configured version to show only the version with a custom format and not help
    And I cd to "tmp/new-gem"
    And my app's name is "new-gem"
    When I successfully run `bin/new-gem --version` with "lib" in the library path
    Then the output should contain:
    """
    new-gem V0.0.1
    """

  Scenario: Won't squash an existing dir
    When I successfully run `methadone tmp/newgem`
    And I run `methadone tmp/newgem`
    Then the exit status should not be 0
    And the stderr should contain:
    """
    error: tmp/newgem exists, use --force to override
    """

  Scenario: WILL squash an existing dir if we use --force
    When I successfully run `methadone tmp/newgem`
    And I run `methadone --force tmp/newgem`
    Then the exit status should be 0

  Scenario: We must supply a dirname
    When I run `methadone`
    Then the exit status should not be 0
    And the stderr should match /'app_name' is required/

  Scenario: Help is properly documented
    When I get help for "methadone"
    Then the exit status should be 0
    And the following options should be documented:
      | --force       | |
      | --readme      | which is negatable       |
      | -l, --license | which is not negatable   |
      | --log-level   | |
    And the banner should be present
    And the banner should document that this app takes options
    And the banner should document that this app's arguments are:
      |app_name|which is required|
    And there should be a one line summary of what the app does

  Scenario: The whole initial state of the app has been staged with git
    Given I successfully run `methadone -l custom tmp/newgem`
    And I cd to "tmp/newgem"
    When I successfully run `git ls-files --others --deleted `
    Then the output should match /\A\Z/

