@wip
Feature: The version should show up in the banner by default
  As a developer
  I should be able to have the current gem version in the banner
  So I don't have to maintain it in two places 
  And so users can easily see the version from the app itself

  Scenario Outline: Show the gem version
    Given I successfully run `methadone tmp/newgem`
    When I cd to "tmp/newgem"
    And I successfully run `bin/newgem <flag>` with "lib" in the library path
    Then the banner should include the version

    Examples:
      |flag      |
      |--help    |
      |--version |
