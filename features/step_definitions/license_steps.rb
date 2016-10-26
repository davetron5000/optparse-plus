Then /^the README should not reference a license$/ do
  step %(the file "tmp/newgem/README.rdoc" should not match /[Ll]icense/)
end

Then /^newgem's license should be the (\w+) license/ do |license|
  @license = license
  step %(a file named "tmp/newgem/LICENSE.txt" should exist)
  step %(the file "tmp/newgem/newgem.gemspec" should match /#{@license.upcase}/)
end

Then /^the README should reference this license$/ do
  step %(the file "tmp/newgem/README.rdoc" should match /License::/)
  step %(the file "tmp/newgem/README.rdoc" should match /#{@license}/)
end


Then /^newgem's license should be an empty file$/ do
  step %(a file named "tmp/newgem/LICENSE.txt" should exist)
  File.read("tmp/aruba/tmp/newgem/LICENSE.txt").should == "\n"
end

Then /^the README should reference the need for a license$/ do
  step %(the file "tmp/newgem/README.rdoc" should match /License:: INSERT LICENSE HERE/)
end

Then(/^LICENSE\.txt should contain user information and program name$/) do
  step %(the file "tmp/newgem/LICENSE.txt" should match /#{`git config user.name`}/)
  step %(the file "tmp/newgem/LICENSE.txt" should match /newgem/)
  step %(the file "tmp/newgem/LICENSE.txt" should match /#{Time.now.year}/)
end
