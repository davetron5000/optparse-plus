require 'bundler'
require 'rake/testtask'
gem 'rdoc'
require 'rdoc/task'
require 'grancher/task'

Bundler::GemHelper.install_tasks

desc 'run tests'
Rake::TestTask.new do |t|
  t.libs << "lib"
  t.libs << "test"
  t.test_files = FileList['test/test_*.rb']
end

desc 'build rdoc'
Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.generator = 'hanna'
  rd.rdoc_files.include("README.rdoc","lib/**/*.rb","bin/**/*")
  rd.title = 'Methadone - Power Up your Command Line Scripts'
end

Grancher::Task.new do |g|
  g.branch = 'gh-pages'
  g.push_to = 'origin'
  g.directory 'html'
end

desc 'Publish rdoc on github pages and push to github'
task :publish_rdoc => [:rdoc,:publish]
