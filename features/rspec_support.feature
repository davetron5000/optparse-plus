Feature: Bootstrap a new command-line app using RSpec instead of Test::Unit
  As an awesome developer who wants to make a command-line app
  I should be able to use methadone to bootstrap it
  And get support for RSpec instead of Test::Unit

  Background:
    Given the directory "tmp/newgem" does not exist

  Scenario: Bootstrap a new app from scratch
    When I successfully run `methadone --rspec tmp/newgem`
    Then the following directories should exist:
      |tmp/newgem/spec                      |
    And the following directories should not exist:
      |tmp/newgem/test                      |
    And the following files should exist:
      |tmp/newgem/spec/something_spec.rb                 |
    And the file "tmp/newgem/newgem.gemspec" should match /add_development_dependency\('rspec', '~> 2.99'/
    When I cd to "tmp/newgem"
    And I successfully run `rake -T -I../../lib`
    Then the output should contain:
    """
    rake spec          # Run RSpec code examples
    """
    And the output should not contain:
    """
    rake test          # Run tests
    """
    When I run `rake spec -I../../lib`
    Then the exit status should be 0
    And the output should contain:
    """
    1 example, 0 failures
    """
