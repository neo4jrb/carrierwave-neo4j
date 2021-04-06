
require "active_graph"

class FakeUserMigration < ActiveGraph::Migrations::Base

  def self.create
    FakeUserMigration.new(:fake_user_migration)
  end

  def up
    add_constraint :User, :uuid, force: true
  end
end
