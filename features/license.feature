Feature: Users should get the license included
  As a user
  I'd like to be able to include a license
  So that I don't have to hunt it down for every new project

  Background:
    Given the directory "tmp/newgem" does not exist

  Scenario: Use a non-stock license
    When I successfully run `methadone -l custom tmp/newgem`
    Then newgem's license should be an empty file
    And the README should reference the need for a license

  Scenario: We only support a few licenses
    When I run `methadone -l foobar tmp/newgem`
    Then the exit status should not be 0
    And the stderr should match /invalid argument: -l foobar/

  Scenario: No license specified
    When I successfully run `methadone tmp/newgem`
    Then the stderr should contain "warning: your app has no license"
    And the README should not reference a license
    And the file "tmp/newgem/LICENSE.txt" should not exist

  Scenario: No license specified explicitly
    When I successfully run `methadone -l NONE tmp/newgem`
    Then the stderr should not contain "warning: your app has no license"
    And the README should not reference a license
    And the file "tmp/newgem/LICENSE.txt" should not exist

  Scenario Outline: Include one of a few stock licenses
    When I successfully run `methadone -l <license> tmp/newgem`
    Then newgem's license should be the <license> license
    And the README should reference this license
    And LICENSE.txt should contain user information and program name

    Examples:
      |license|
      |apache|
      |mit|
      |gplv2|
      |gplv3|

