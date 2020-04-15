
require 'helpers/fake_schema_migration'
require 'helpers/fake_user_migration'
require 'helpers/fake_book_migration'

class FakeMigrations
  def self.migrate(direction)
    FakeSchemaMigration.create.migrate(direction)
    FakeUserMigration.create.migrate(direction)
    FakeBookMigration.create.migrate(direction)
  end
end
