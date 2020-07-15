
require "neo4j"

class FakeSchemaMigration < Neo4j::Migrations::Base

  def self.create
    FakeSchemaMigration.new(:fake_schema_migration)
  end

  def up
    add_constraint :"Neo4j::Migrations::SchemaMigration", :migration_id, force: true
  end
end
