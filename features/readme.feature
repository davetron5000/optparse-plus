Feature: a README should be generated
  As a user
  I want a template README
  So I don't need to recall the formatting or other info to get started

  Background:
    Given the directory "tmp/newgem" does not exist

  Scenario: I don't want a README
    When I successfully run `methadone --no-readme tmp/newgem`
    Then a README should not be generated
    And the file "tmp/newgem/Rakefile" should not match /rd.main = "README.rdoc"/

  Scenario Outline: Generate README
    When I successfully run `methadone <flag> tmp/newgem`
    Then a README should be generated in RDoc
    And the README should contain the project name
    And the README should contain my name
    And the README should contain links to Github and RDoc.info
    And the README should contain empty sections for common elements of a README
    And the file "tmp/newgem/Rakefile" should match /rd.main = "README.rdoc"/

    Examples:
      |flag|
      | |
      |--readme|
