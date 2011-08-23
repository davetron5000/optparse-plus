require 'fileutils'
include FileUtils

Given /^the directory "([^"]*)" does not exist$/ do |dir|
  dir = File.join(ARUBA_DIR,dir)
  rm_rf dir,:verbose => false, :secure => true
end
