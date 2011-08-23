Feature: Bootstrap a new command-line app
  As an awesome developer who wants to make a command-line app
  I should be able to use methadone to bootstrap it
  And get all kinds of cool things

  @announce
  Scenario: Bootstrap a new app from scratch
    Given an empty directory named "tmp/newgem"
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
    And the following files should exist:
      |tmp/newgem/newgem.gemspec                            |
      |tmp/newgem/Rakefile                                  |
      |tmp/newgem/Gemfile                                   |
      |tmp/newgem/bin/newgem                                |
      |tmp/newgem/features/newgem.feature                   |
      |tmp/newgem/features/support/env.rb                   |
      |tmp/newgem/features/step_definitions/newgem_steps.rb |
      |tmp/newgem/test/tc_something.rb                      |
    Given I cd to "tmp/newgem"
    #Then I successfully run `bundle install`
    When I run `rake`
    Then the exit status should be 0
    And the output should contain:
    """
    1 tests, 1 assertions, 0 failures, 0 errors, 0 skips
    """
    And the output should contain:
    """
    1 scenario (1 passed)
    3 steps (3 passed)
    """
