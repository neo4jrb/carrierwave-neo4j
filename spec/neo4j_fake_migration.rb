
require "neo4j"

class Neo4jFakeMigration < Neo4j::Migrations::Base

  def self.create
    Neo4jFakeMigration.new(:fake_migration)
  end

  def up
    add_constraint :"Neo4j::Migrations::SchemaMigration", :migration_id, force: true
    add_constraint :User, :uuid, force: true
  end
end
