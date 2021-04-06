require "rubygems"
require "bundler/setup"
require "rake"
require "rspec"
require "rspec/its"
require "webmock/rspec"

require "active_graph"
require "helpers/database_cleaner"
require "helpers/filesystem_cleaner"
require "helpers/fake_migrations"

require "carrierwave"
require "carrierwave/neo4j"

def file_path(*paths)
  File.expand_path(File.join(File.dirname(__FILE__), "fixtures", *paths))
end

def public_path(*paths)
  File.expand_path(File.join(File.dirname(__FILE__), "public", *paths))
end

def tmp_path( *paths )
  File.expand_path(File.join(File.dirname(__FILE__), 'public/uploads/tmp', *paths))
end

CarrierWave.root = public_path
# DatabaseCleaner[:neo4j, connection: {type: :bolt, path: 'bolt://localhost:7006'}].strategy = :transaction

server_url = ENV['NEO4J_URL'] || 'bolt://localhost:7472'
ActiveGraph::Base.driver =
    Neo4j::Driver::GraphDatabase.driver(server_url, Neo4j::Driver::AuthTokens.none, encryption: false)

RSpec.configure do |config|
  config.before(:each) do
    DatabaseCleaner.avoid_validation do 
      DatabaseCleaner.clean
      FilesystemCleaner.clean
      FakeMigrations.migrate(:up)
    end
  end

  config.after(:each) do
    DatabaseCleaner.avoid_validation { DatabaseCleaner.clean }
  end
end
