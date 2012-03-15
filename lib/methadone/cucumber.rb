module Methadone
  # By <tt>require</tt>'ing <tt>methadone/cucumber</tt> in your Cucumber setup (e.g. in <tt>env.rb</tt>), you
  # gain access to the steps defined in this file.  They provide you with the following:
  #
  # * Run <tt>command_to_run --help</tt> using aruba
  # 
  #     When I get help for "command_to_run"
  # 
  # * Make sure that each option shows up in the help and has *some* sort of documentation
  # 
  #     Then the following options should be documented:
  #       |--force|
  #       |-x     |
  # 
  # * Check an individual option for documentation:
  # 
  #     Then the option "--force" should be documented
  # 
  # * Checks that the help has a proper usage banner
  # 
  #     Then the banner should be present
  # 
  # * Checks that the banner includes the version
  # 
  #     Then the banner should include the version
  # 
  # * Checks that the usage banner indicates it takes options via <tt>[options]</tt>
  # 
  #     Then the banner should document that this app takes options
  # 
  # * Do the opposite; check that you don't indicate options are accepted
  # 
  #     Then the banner should document that this app takes no options
  # 
  # * Checks that the app's usage banner documents that its arguments are <tt>args</tt>
  # 
  #     Then the banner should document that this app's arguments are
  #       |foo|which is optional|
  #       |bar|which is required|
  # 
  # * Do the opposite; check that your app doesn't take any arguments
  # 
  #     Then the banner should document that this app takes no arguments
  # 
  # * Check for a usage description which occurs after the banner and a blank line
  # 
  #     Then there should be a one line summary of what the app does
  # 
  module Cucumber
  end
end
When /^I get help for "([^"]*)"$/ do |app_name|
  @app_name = app_name
  step %(I run `#{app_name} --help`)
end

Then /^the following options should be documented:$/ do |options|
  options.raw.each do |option|
    step %(the option "#{option[0]}" should be documented)
  end
end

Then /^the option "([^"]*)" should be documented$/ do |option|
  step %(the output should match /\\s*#{Regexp.escape(option)}[\\s\\W]+\\w\\w\\w+/)
end

Then /^the banner should be present$/ do
  step %(the output should match /Usage: #{@app_name}/)
end

Then /^the banner should document that this app takes options$/ do
  step %(the output should match /\[options\]/)
  step %(the output should contain "Options")
end

Then /^the banner should document that this app's arguments are:$/ do |table|
  expected_arguments = table.raw.map { |row|
    option = row[0]
    option = "[#{option}]" if row[1] == 'optional' || row[1] == 'which is optional'
    option
  }.join(' ')
  step %(the output should contain "#{expected_arguments}")
end

Then /^the banner should document that this app takes no options$/ do
  step %(the output should not contain "[options]")
  step %(the output should not contain "Options")
end

Then /^the banner should document that this app takes no arguments$/ do
  step %(the output should match /Usage: #{@app_name}\\s*\(\\[options\\]\)?$/)
end

Then /^the banner should include the version$/ do
  step %(the output should match /v\\d+\\.\\d+\\.\\d+/)
end

Then /^there should be a one line summary of what the app does$/ do
  output_lines = all_output.split(/\n/)
  output_lines.should have_at_least(3).items
  # [0] is our banner, which we've checked for
  output_lines[1].should match(/^\s*$/)
  output_lines[2].should match(/^\w\w+\s+\w\w+/)
end
