require 'bundler/gem_tasks'
require 'neo4j/rake_tasks'

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)

  task :default => :spec
rescue LoadError
  puts "RSpec not installed...?"
end
