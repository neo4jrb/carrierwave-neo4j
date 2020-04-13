
require "neo4j"

class DirtyCleaner
  include Neo4j::Migrations::Helpers

  def clean
    clean_db
    clean_fs
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

  def clean_fs
    FileUtils.rm_rf("spec/public/uploads/*.jpg")
    FileUtils.rm_rf("spec/public/uploads/tmp/")
  end

  def avoid_validation
    # migrations and db cleanup have to happen outside of validations
    # or they never succeed
    Neo4j::Migrations.currently_running_migrations = true
    yield
    Neo4j::Migrations.currently_running_migrations = false
  end
end
