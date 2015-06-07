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

Given /^"(.*?)" has configured version to show only the version (.*)and not help$/ do |gemname,extras|
  lines = File.read("tmp/aruba/tmp/new-gem/#{gemname}").split(/\n/)
  File.open("tmp/aruba/tmp/new-gem/#{gemname}","w") do |file|
    lines.each do |line|
      if line =~ /^\s*version New::Gem::VERSION/
        if extras =~ /with a custom format/
          file.puts line + ", :compact => true, :format => '%s V%s'"
        else
          file.puts line + ", :compact => true"
        end
      else
        file.puts line
      end
    end
  end
end

Then /^the file "(.*?)" should include "(.*?)" if needed$/ do |file, gemname|
  if RUBY_VERSION =~ /^2\./ && RUBY_VERSION !~ /^2.0/ && RUBY_VERSION !~ /^2.1/
    step %{the file "#{file}" should match /add_development_dependency\\('#{gemname}/}
  end
end
