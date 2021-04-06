
require "active_graph"

class FakeBookMigration < ActiveGraph::Migrations::Base

  def self.create
    FakeBookMigration.new(:fake_book_migration)
  end

  def up
    add_constraint :Book, :uuid, force: true
  end
end
