Then /^a README should not be generated$/ do
  step %(the file "tmp/newgem/README.rdoc" should not exist)
end

Then /^a README should be generated in RDoc$/ do
  step %(a file named "tmp/newgem/README.rdoc" should exist)
end

Then /^the README should contain the project name$/ do
  step %(the file "tmp/newgem/README.rdoc" should match /newgem/)
end

Then /^the README should contain my name$/ do
  step %(the file "tmp/newgem/README.rdoc" should match /Author::  YOUR NAME \\\(YOUR EMAIL\\\)/)
end

Then /^the README should contain links to Github and RDoc.info$/ do
  step %(the file "tmp/newgem/README.rdoc" should match /\\\* \\\{Source on Github\\\}\\\[LINK TO GITHUB\\\]/)
  step %(the file "tmp/newgem/README.rdoc" should match /RDoc\\\[LINK TO RDOC.INFO\\\]/)
end

Then /^the README should contain empty sections for common elements of a README$/ do
  step %(the file "tmp/newgem/README.rdoc" should match /^== Install/)
  step %(the file "tmp/newgem/README.rdoc" should match /^== Examples/)
  step %(the file "tmp/newgem/README.rdoc" should match /^== Contributing/)
end
