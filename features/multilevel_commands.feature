Feature: Support multi-level commands
  As a developer who wants to make a multi-level command line app
  I should be able to create a Methadone class that delegates subcommands to other Methadone classes
  and each should support their own options, args and potentially other subcommands.

  Background:
    Given the directory "tmp/multigem" does not exist

  Scenario: Bootstrap a multi-level app from scratch
    When I successfully run `methadone --commands walk,run,crawl,dance tmp/multigem`
    Then the following directories should exist:
      |tmp/multigem                           |
      |tmp/multigem/bin                       |
      |tmp/multigem/lib                       |
      |tmp/multigem/lib/multigem              |
      |tmp/multigem/lib/multigem/commands     |
      |tmp/multigem/test                      |
      |tmp/multigem/features                  |
      |tmp/multigem/features/support          |
      |tmp/multigem/features/step_definitions |
    Then the following directories should not exist:
      |tmp/multigem/spec |
    And the following files should exist:
      |tmp/multigem/multigem.gemspec                            |
      |tmp/multigem/Rakefile                                    |
      |tmp/multigem/.gitignore                                  |
      |tmp/multigem/Gemfile                                     |
      |tmp/multigem/bin/multigem                                |
      |tmp/multigem/lib/multigem/version.rb                     |
      |tmp/multigem/lib/multigem/commands/walk.rb               |
      |tmp/multigem/lib/multigem/commands/run.rb                |
      |tmp/multigem/lib/multigem/commands/crawl.rb              |
      |tmp/multigem/lib/multigem/commands/dance.rb              |
      |tmp/multigem/features/multigem.feature                   |
      |tmp/multigem/features/support/env.rb                     |
      |tmp/multigem/features/step_definitions/multigem_steps.rb |
      |tmp/multigem/test/tc_something.rb                        |
    And the file "tmp/multigem/.gitignore" should match /results.html/
    And the file "tmp/multigem/.gitignore" should match /html/
    And the file "tmp/multigem/.gitignore" should match /pkg/
    And the file "tmp/multigem/.gitignore" should match /.DS_Store/
    And the file "tmp/multigem/multigem.gemspec" should match /add_development_dependency\('aruba'/
    And the file "tmp/multigem/multigem.gemspec" should match /add_development_dependency\('rdoc'/
    And the file "tmp/multigem/multigem.gemspec" should match /add_development_dependency "rake", "~> 10.0"/
    And the file "tmp/multigem/multigem.gemspec" should match /add_dependency\('methadone'/
    And the file "tmp/multigem/multigem.gemspec" should use the same block variable throughout
    And the file "tmp/multigem/bin/multigem" should match /command "walk" => Multigem::Commands::Walk/
    And the file "tmp/multigem/bin/multigem" should match /command "run" => Multigem::Commands::Run/
    And the file "tmp/multigem/bin/multigem" should match /command "crawl" => Multigem::Commands::Crawl/
    And the file "tmp/multigem/bin/multigem" should match /command "dance" => Multigem::Commands::Dance/
    Given I cd to "tmp/multigem"
    And my app's name is "multigem"
    When I successfully run `bin/multigem --help` with "lib" in the library path
    Then the banner should be present
    And the banner should document that this app takes options
    And the banner should document that this app takes commands
    And the following commands should be documented:
      |walk  |
      |run   |
      |crawl |
      |dance |
    And the following options should be documented:
      |--version|
      |--help|
      |--log-level|

  Scenario: Special characters in subcommands and gem name
    Given a directory named "tmp"
    And the directory "tmp/multigem2" does not exist
    When I run `methadone --add-lib --commands walk,run,crawl_to_bed,tap-dance,@go-crazy tmp/multigem2`
    Then the exit status should be 0
    And the following directories should exist:
      |tmp/multigem2                            |
      |tmp/multigem2/bin                        |
      |tmp/multigem2/lib                        |
      |tmp/multigem2/lib/multigem2              |
      |tmp/multigem2/lib/multigem2/commands     |
      |tmp/multigem2/test                       |
      |tmp/multigem2/features                   |
      |tmp/multigem2/features/support           |
      |tmp/multigem2/features/step_definitions  |
    And the following directories should not exist:
      |tmp/multigem2/spec |
    And the following files should exist:
      |tmp/multigem2/multigem2.gemspec                             |
      |tmp/multigem2/Rakefile                                     |
      |tmp/multigem2/.gitignore                                   |
      |tmp/multigem2/Gemfile                                      |
      |tmp/multigem2/bin/multigem2                                |
      |tmp/multigem2/lib/multigem2/version.rb                     |
      |tmp/multigem2/lib/multigem2/commands/walk.rb               |
      |tmp/multigem2/lib/multigem2/commands/run.rb                |
      |tmp/multigem2/lib/multigem2/commands/crawl_to_bed.rb       |
      |tmp/multigem2/lib/multigem2/commands/tap_dance.rb          |
      |tmp/multigem2/lib/multigem2/commands/go_crazy.rb           |
      |tmp/multigem2/features/multigem2.feature                   |
      |tmp/multigem2/features/support/env.rb                      |
      |tmp/multigem2/features/step_definitions/multigem2_steps.rb |
      |tmp/multigem2/test/tc_something.rb                         |
    And the file "tmp/multigem2/bin/multigem2" should match /command "walk" => Multigem2::Commands::Walk/
    And the file "tmp/multigem2/bin/multigem2" should match /command "run" => Multigem2::Commands::Run/
    And the file "tmp/multigem2/bin/multigem2" should match /command "crawl_to_bed" => Multigem2::Commands::CrawlToBed/
    And the file "tmp/multigem2/bin/multigem2" should match /command "tap-dance" => Multigem2::Commands::TapDance/
    And the file "tmp/multigem2/bin/multigem2" should match /command "@go-crazy" => Multigem2::Commands::GoCrazy/
    Given I cd to "tmp/multigem2"
    And my app's name is "multigem2"
    When I successfully run `bin/multigem2 --help`
    Then the banner should be present
    And the banner should document that this app takes options
    And the banner should document that this app takes commands
    And the following commands should be documented:
      |walk         |
      |run          |
      |crawl_to_bed |
      |tap-dance    |
      |@go-crazy    |
    And the following options should be documented:
      |--version|
      |--help|
      |--log-level|
    When I successfully run `bin/multigem2 tap-dance -h`
    Then the banner should be present
    And the banner should document that this app takes global options
    And the banner should document that this app takes options

