Feature: As a User I want to use Rspec 
  In order to use methadone
  As a User 
  I want to have rspec 2.99

  Scenario: Rspec version test
    When I run `rspec --version`
    Then the output should contain exactly "2.99.1\n"
