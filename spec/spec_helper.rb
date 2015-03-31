require "rubygems"
require "bundler/setup"
require "rspec"
require "rspec/its"

require "carrierwave"
require "carrierwave/neo4j"
require "database_cleaner"

def file_path(*paths)
  File.expand_path(File.join(File.dirname(__FILE__), "fixtures", *paths))
end

def public_path(*paths)
  File.expand_path(File.join(File.dirname(__FILE__), "public", *paths))
end

CarrierWave.root = public_path
DatabaseCleaner[:neo4j, connection: {type: :server_db, path: 'http://localhost:7475'}].strategy = :transaction

RSpec.configure do |config|
  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end

