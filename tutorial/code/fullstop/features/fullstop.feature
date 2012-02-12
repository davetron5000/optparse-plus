Feature: Checkout dotfiles
  In order to get my dotfiles onto a new computer
  I want a one-command way to keep them up to date
  So I don't have to do it myself

  Scenario: Basic UI
    When I get help for "fullstop"
    Then the exit status should be 0
    And the banner should be present
    And there should be a one line summary of what the app does
    And the banner should include the version
    And the banner should document that this app takes options
    And the banner should document that this app's arguments are:
      |repo_url|which is required|
    And the following options should be documented:
      | --force        |
      | --checkout-dir |
      | -d             |

  Scenario: Happy Path
    Given a git repo with some dotfiles at "/tmp/dotfiles.git"
    When I successfully run `fullstop file:///tmp/dotfiles.git`
    Then the dotfiles should be checked out in the directory "~/dotfiles"
    And the files in "~/dotfiles" should be symlinked in my home directory
