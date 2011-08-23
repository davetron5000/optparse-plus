require 'bundler'
require 'rake/clean'
require 'rake/testtask'
gem 'rdoc'
require 'rdoc/task'
require 'grancher/task'
require 'cucumber'
require 'cucumber/rake/task'

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
  rd.title = 'Methadone - Power Up your Command Line Apps'
end

Grancher::Task.new do |g|
  g.branch = 'gh-pages'
  g.push_to = 'origin'
  g.directory 'html'
end

CUKE_RESULTS = 'results.html'
CLEAN << CUKE_RESULTS
Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "features --format html -o #{CUKE_RESULTS} --format progress -x"
  t.fork = false
end

desc 'Publish rdoc on github pages and push to github'
task :publish_rdoc => [:rdoc,:publish]
