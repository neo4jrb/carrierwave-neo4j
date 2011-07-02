require "rubygems"
require "bundler/setup"
require "rspec"

require "carrierwave"
require "carrierwave/neo4j"

def file_path(*paths)
  File.expand_path(File.join(File.dirname(__FILE__), "fixtures", *paths))
end

def public_path(*paths)
  File.expand_path(File.join(File.dirname(__FILE__), "public", *paths))
end

CarrierWave.root = public_path
