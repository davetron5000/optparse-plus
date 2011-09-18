When /^I get help for "([^"]*)"$/ do |app_name|
  @app_name = app_name
  When %(I run `#{app_name} --help`)
end

Then /^the following options should be documented:$/ do |options|
  options.raw.each do |option|
    Then %(the option "#{option[0]}" should be documented)
  end
end

Then /^the option "([^"]*)" should be documented$/ do |option|
  Then %(the output should match /^\\s*#{option}\\s+\\w\\w\\w+/)
end

Then /^the banner should be present$/ do
  Then %(the output should match /Usage: #{@app_name}/)
end

Then /^the banner should document that this app takes options$/ do
  Then %(the output should match /\[options\]/)
end

Then /^the banner should document that this app's arguments are:$/ do |table|
  expected_arguments = table.raw.map { |row|
    option = row[0]
    option = "[#{option}]" if row[1] == 'optional' || row[1] == 'which is optional'
  }.join(' ')
  Then %(the output should contain "#{expected_arguments}")
end
