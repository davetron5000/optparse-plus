require 'fileutils'
include FileUtils

Given /^an empty directory named "([^"]*)"$/ do |dir|
  dir = File.join(ARUBA_DIR,dir)
  #raise "dir should be in /tmp, not in #{File.split(dir)[0]}" unless File.split(dir)[0] == "/tmp"
  rm_rf dir,:verbose => false, :secure => true
  mkdir_p dir
end
