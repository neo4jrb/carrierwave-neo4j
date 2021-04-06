
require "active_graph"

class DatabaseCleaner
  include ActiveGraph::Migrations::Helpers

  def self.clean
    DatabaseCleaner.new.clean_db
  end
  
  def self.avoid_validation
    # migrations and db cleanup have to happen outside of validations
    # or they never succeed
    ActiveGraph::Migrations.currently_running_migrations = true
    yield
    ActiveGraph::Migrations.currently_running_migrations = false
  end

  def clean_db
    execute("match (n) detach delete n;")
    execute("call db.constraints").each do |constraint|
      execute "drop #{constraint[:description]}"
    end
    execute("call db.indexes").each do |index|
      execute "drop #{index[:description]}"
    end
  end

end
