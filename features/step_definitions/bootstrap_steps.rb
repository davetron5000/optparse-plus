require 'fileutils'
include FileUtils

Given /^the directory "([^"]*)" does not exist$/ do |dir|
  dir = File.join(ARUBA_DIR,dir)
  rm_rf dir,:verbose => false, :secure => true
end

Given /^my app's name is "([^"]*)"$/ do |app_name|
  @app_name = app_name
end

Then /^the file "([^"]*)" should use the same block variable throughout$/ do |file|
  prep_for_fs_check do
    content = IO.read(file)
    from_bundler = content.match(/(\w+)\.authors/)[1]
    added_by_methadone = content.match(/(\w+).add_development_dependency\('rdoc'/)[1]
    from_bundler.should == added_by_methadone
  end
end

Then /^the stderr should match \/([^\/]*)\/$/ do |expected|
  assert_matching_output(expected, all_stderr)
end

