require 'sdoc'
require 'bundler'
require 'rake/clean'
require 'rake/testtask'
require 'cucumber'
require 'cucumber/rake/task'

include Rake::DSL

Bundler::GemHelper.install_tasks

desc 'run tests'
Rake::TestTask.new do |t|
  t.libs << "lib"
  t.libs << "test"
  t.ruby_opts << "-rrubygems"
  t.test_files = FileList['test/test_*.rb'] + FileList['test/execution_strategy/test_*.rb']
end

desc 'build rdoc'
RDoc::Task.new do |rd|
  rd.main = "README.rdoc"
  rd.options << '-f' << 'sdoc'
  rd.template = 'direct'
  rd.rdoc_files.include("README.rdoc","lib/**/*.rb","bin/**/*")
  rd.title = 'Methadone - Power Up your Command Line Apps'
end
CLOBBER << 'html'

if RUBY_PLATFORM == 'java'
task :features do
  puts "Aruba doesn't work on JRuby; cannot run features"
end
task 'features:wip' => :features
else
CUKE_RESULTS = 'results.html'
CLEAN << CUKE_RESULTS
Cucumber::Rake::Task.new(:features) do |t|
  tag_opts = ' --tags ~@pending'
  tag_opts = " --tags #{ENV['TAGS']}" if ENV['TAGS']
  t.cucumber_opts = "features --format html -o #{CUKE_RESULTS} --format pretty -x -s#{tag_opts}"
  t.fork = false
end

Cucumber::Rake::Task.new('features:wip') do |t|
  tag_opts = ' --tags ~@pending'
  tag_opts = ' --tags @wip'
  t.cucumber_opts = "features --format html -o #{CUKE_RESULTS} --format pretty -x -s#{tag_opts}"
  t.fork = false
end
end

CLEAN << "coverage"
CLOBBER << FileList['**/*.rbc']
task :default => [:test, :features]
