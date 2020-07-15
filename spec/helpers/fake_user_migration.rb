
require "neo4j"

class FakeUserMigration < Neo4j::Migrations::Base

  def self.create
    FakeUserMigration.new(:fake_user_migration)
  end

  def up
    add_constraint :User, :uuid, force: true
  end
end
