Then /^the README should not reference a license$/ do
  step %(the file "tmp/newgem/README.rdoc" should not match /[Ll]icense/)
end

Then /^newgem's license should be the (\w+) license/ do |license|
  @license = license
  step %(a file named "tmp/newgem/LICENSE.txt" should exist)
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

