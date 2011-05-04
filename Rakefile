require 'bundler'
require 'rake/testtask'
require 'rake/rdoctask'
require 'sdoc'

Bundler::GemHelper.install_tasks

Rake::TestTask.new do |t|
  t.libs << "lib"
  t.libs << "test"
  t.test_files = FileList['test/test_*.rb']
end

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc","lib/**/*.rb","bin/**/*")
  rd.options << '--fmt' << 'shtml'
  rd.template = 'direct'
  rd.title = 'Git Like Interface'
end
