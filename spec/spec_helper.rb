require "rubygems"
require "bundler/setup"
require "rake"
require "rspec"
require "rspec/its"

require "neo4j"
require "neo4j/core/cypher_session/adaptors/bolt"
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
# DatabaseCleaner[:neo4j, connection: {type: :bolt, path: 'bolt://localhost:7003'}].strategy = :transaction

neo4j_adaptor = Neo4j::Core::CypherSession::Adaptors::Bolt.new('bolt://localhost:7003', {ssl: false})
Neo4j::ActiveBase.on_establish_session { Neo4j::Core::CypherSession.new(neo4j_adaptor) }

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
