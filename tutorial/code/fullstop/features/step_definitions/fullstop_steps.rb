include FileUtils

FILES = %w(.vimrc .bashrc .exrc)
NEW_FILE = '.inputrc'

Given /^a git repo with some dotfiles at "([^"]*)"$/ do |repo_dir|
  @repo_dir = repo_dir
  base_dir = File.dirname(repo_dir)
  dir = File.basename(repo_dir)
  puts base_dir
  puts dir
  Dir.chdir base_dir do
    rm_rf dir
    mkdir dir
  end
  Dir.chdir repo_dir do
    FILES.each { |_| touch _ }
    sh "git init ."
    sh "git add #{FILES.join(' ')}"
    sh "git commit -a -m 'initial commit'"
  end
end

Then /^the dotfiles should be checked out in the directory "([^"]*)"$/ do |dotfiles_dir|
  @files = @files_override || FILES
  # Expand ~ to ENV["HOME"]
  base_dir = File.dirname(dotfiles_dir)
  base_dir = ENV['HOME'] if base_dir == "~"
  dotfiles_dir = File.join(base_dir,File.basename(dotfiles_dir))

  File.exist?(dotfiles_dir).should == true
  Dir.chdir dotfiles_dir do
    @files.each do |file|
      File.exist?(file).should == true
    end
  end
end

Then /^the files in "([^"]*)" should be symlinked in my home directory$/ do |dotfiles_dir|
  @files = @files_override || FILES
  Dir.chdir(ENV['HOME']) do
    @files.each do |file|
      File.lstat(file).should be_symlink
    end
  end
end

Given /^I have my dotfiles cloned and symlinked to "([^"]*)"$/ do |dir|
  step %{I successfully run `fullstop file://#{@repo_dir}`}
end

Given /^there's a new file in the git repo$/ do
  Dir.chdir @repo_dir do
    touch NEW_FILE
    sh "git add #{NEW_FILE}"
    sh "git commit -m 'added'"
  end
end

Then /^the dotfiles in "([^"]*)" should be re\-cloned$/ do |dir|
  @files_override = FILES + [NEW_FILE]
  step %{the dotfiles should be checked out in the directory "#{dir}"}
end

