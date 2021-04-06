
require "active_graph"

class FakeSchemaMigration < ActiveGraph::Migrations::Base

  def self.create
    FakeSchemaMigration.new(:fake_schema_migration)
  end

  def up
    add_constraint :"ActiveGraph::Migrations::SchemaMigration", :migration_id, force: true
  end
end
