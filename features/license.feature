@pending
Feature: Users should get the license included
  As a user
  I'd like to be able to include a license
  So that I don't have to hunt it down for every new project

  Scenario: Use a custom license
    Given a custom license is available at http://localhost:1234/my_license.txt
    When I run successfully `methadone -l my_license --license-location=http://localhost:1234 newgem`
    Then newgem's license should identical to the file at http://localhost:1234/my_license.txt
    And the README should reference the license my_license

  Scenario Outline: Include one of a few stock licenses
    When I run successfully `methadone -l <license> newgem`
    Then newgem's license should be the <license> license
    And the README should reference this license

    Examples:
      |<license>|
      |apache|
      |gpl|
      |mit|

  Scenario: No license specified
    When I run successfully `methadone newgem`
    Then the stderr should contain "Warning: your app has no license"
    And the README should not reference a license
