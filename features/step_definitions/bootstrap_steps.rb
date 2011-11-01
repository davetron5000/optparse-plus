require 'fileutils'
include FileUtils

Given /^the directory "([^"]*)" does not exist$/ do |dir|
  dir = File.join(ARUBA_DIR,dir)
  rm_rf dir,:verbose => false, :secure => true
end

Given /^my app's name is "([^"]*)"$/ do |app_name|
  @app_name = app_name
end

Then /^the stderr should match \/([^\/]*)\/$/ do |expected|
  assert_matching_output(expected, all_stderr)
end

