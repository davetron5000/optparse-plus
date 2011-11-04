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
  step %(the output should match /^\\s*#{option}\\s+\\w\\w\\w+/)
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
  }.join(' ')
  step %(the output should contain "#{expected_arguments}")
end

Then /^the banner should document that this app takes no options$/ do
  step %(the output should not contain "[options]")
  step %(the output should not contain "Options")
end

Then /^the banner should document that this app takes no arguments$/ do
  step %(the output should match /Usage: #{@app_name}\\s*$/)
end

Then /^there should be a one line summary of what the app does$/ do
  output_lines = all_output.split(/\n/)
  output_lines.should have_at_least(3).items
  # [0] is our banner, which we've checked for
  output_lines[1].should match(/^\s*$/)
  output_lines[2].should match(/^\w\w+\s+\w\w+/)
end
