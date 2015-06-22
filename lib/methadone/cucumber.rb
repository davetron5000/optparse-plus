module Methadone
  # By <tt>require</tt>'ing <tt>methadone/cucumber</tt> in your Cucumber setup (e.g. in <tt>env.rb</tt>), you
  # gain access to the steps defined in this file.  They provide you with the following:
  #
  # * Run <tt>command_to_run --help</tt> using aruba
  #
  #     When I get help for "command_to_run"
  #
  # * Make sure that each option shows up in the help and has *some* sort of documentation.  By default,
  #   the options won't be required to be negatable.
  #
  #     Then the following options should be documented:
  #       |--force|
  #       |-x     |
  #
  #     Then the following options should be documented:
  #       |--force| which is negatable     |
  #       |-x     | which is not negatable |
  #
  # * Check an individual option for documentation:
  #
  #     Then the option "--force" should be documented
  #     Then the option "--force" should be documented which is negatable
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

Given /^PENDING/ do
  pending "test needs to be written"
end

When /^I get help for "([^"]*)"$/ do |app_name|
  @app_name = app_name
  step %(I run `#{app_name} --help`)
end

When /^I get help for "([^"]*)" subcommand "([^"]*)"$/ do |app_name,subcommands|
  @app_name = app_name
  @subcommands = subcommands.split(/\s+/)
  step %(I run `#{app_name} #{subcommands} --help`)
end

Then /^the following (argument|option)s should be documented:$/ do |type,table|
  table.raw.each do |row|
    step %(the #{type} "#{row[0]}" should be documented #{row[1]})
  end
end

Then /^there should be (\d+) options listed$/ do |option_count|
  match = all_output.match(/(?m)Options:\n((?:(?!\n\n).)*)(?:\n\n|\z)/)
  real_option_count = match[1].chomp.split(/\n/).select {|l| l =~ /^ *-/}.length
  real_option_count.should == option_count.to_i
end

Then /^the option "([^"]*)" should be documented(.*)$/ do |options,qualifiers|
  options.split(',').map(&:strip).each do |option|
    if qualifiers.strip == "which is negatable"
      option = option.gsub(/^--/,"--[no-]")
    end
    step %(the output should match /\\s*#{Regexp.escape(option)}[\\s\\W]+\\w[\\s\\w][\\s\\w]+/)
  end
end

Then /^the following (commands|global options) should be documented:$/ do |type, table|
  table.raw.each do |row|
    step %(the output should match /(?m)#{type.capitalize}:((?!\\n\\n).)*\\n +#{Regexp.escape(row[0])}/)
  end
end

Then /^there should be (\d+) command listed$/ do |command_count|
  match = all_output.match(/(?m)Commands:\n((?:  [^\n]*\n)+)(\n|\z)/)
  real_command_count = match[1].chomp.split(/\n/).length
  real_command_count.should == command_count.to_i.should
end

Then /^the banner should be present$/ do
  step %(the output should match /Usage: #{@app_name}/)
end

Then /^the banner should document that this app takes options$/ do
  step %(the output should match /\[options\]/)
  step %(the output should contain "Options")
end

Then /^the banner should document that this app takes global options$/ do
  step %(the output should match /\[global options\]/)
  step %(the output should contain "Global options")
end

Then /^the banner should document that this app takes commands$/ do
  step %(the output should match /command \[command options and args...\]/)
  step %(the output should contain "\\nCommands:")
end

Then /^the banner should document that this app's arguments are:$/ do |table|
  expected_arguments = table.raw.map { |row|
    option = row[0]
    option = "#{option}..." if row[1] =~ /(?:which can take )?(many|any)( values)?/
    option = "[#{option}]" if row[1] =~ /(which is optional|which can take any( values)?|optional|any)/
    option
  }.join(' ')
  step %(the output should contain "#{expected_arguments}")
end

Then /^there should be (\d+) arguments? listed$/ do |arg_count|
  match = all_output.match(/(?m)\nArguments:\n((?:    [^\n]*\n)+)(?:\n|\z)/)
  real_arg_count = match[1].chomp.split(/\n    (?=[^ ])/).length
  real_arg_count.should == arg_count.to_i
end

Then /^the argument "([^"]*)" should be documented(.*)$/ do |arg,qualifiers|
  if qualifiers.strip == "which is optional"
    arg += " (optional)"
  end
  step %(the output should match /(?m)Arguments:((?!\\n\\n).)*\\n    #{Regexp.escape(arg)}/)
end

Then /^the banner should document that this app takes no options$/ do
  step %(the output should not contain "[options]")
  step %(the output should not contain "^Options:")
end

Then /^the banner should document that this app takes no arguments$/ do
  step %(the output should match /Usage: #{@app_name}\\s*\(\\[options\\]\)?$/)
end

Then /^the banner should document that this app takes no commands$/ do
  step %(the output should not match /command \[command options and args...\]/)
  step %(the output should not contain "\\nCommands:")
end

Then /^the banner should include the version$/ do
  step %(the output should match /v\\d+\\.\\d+\\.\\d+/)
end

Then /^there should be a one line summary of what the app does$/ do
  output_lines = all_output.split(/\n/)
  output_lines.size.should >= 4
  # [0] is a blank line,
  # [1] is our banner, which we've checked for
  output_lines[2].should match(/^\s*$/)
  output_lines[3].should match(/^\w+\s+\w+/)
end
