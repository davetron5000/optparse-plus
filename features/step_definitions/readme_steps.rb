Then /^a README should not be generated$/ do
  Then %(the file "tmp/newgem/README.rdoc" should not exist)
end

Then /^a README should be generated in RDoc$/ do
  Then %(a file named "tmp/newgem/README.rdoc" should exist)
end

Then /^the README should contain the project name$/ do
  Then %(the file "tmp/newgem/README.rdoc" should match /newgem/)
end

Then /^the README should contain my name$/ do
  Then %(the file "tmp/newgem/README.rdoc" should match /Author::  YOUR NAME \\\(YOUR EMAIL\\\)/)
end

Then /^the README should contain links to Github and RDoc.info$/ do
  Then %(the file "tmp/newgem/README.rdoc" should match /\\\* \\\{Source on Github\\\}\\\[LINK TO GITHUB\\\]/)
  Then %(the file "tmp/newgem/README.rdoc" should match /RDoc\\\[LINK TO RDOC.INFO\\\]/)
end

Then /^the README should contain empty sections for common elements of a README$/ do
  Then %(the file "tmp/newgem/README.rdoc" should match /^== Install/)
  Then %(the file "tmp/newgem/README.rdoc" should match /^== Examples/)
  Then %(the file "tmp/newgem/README.rdoc" should match /^== Contributing/)
end
