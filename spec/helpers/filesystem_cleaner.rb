
require "neo4j"

class FilesystemCleaner
  def self.clean
    FilesystemCleaner.new.clean_fs
  end

  def clean_fs
    FileUtils.rm_rf("spec/public/uploads")
  end
end
