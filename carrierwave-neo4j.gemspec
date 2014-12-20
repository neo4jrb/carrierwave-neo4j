# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "carrierwave/neo4j/version"

Gem::Specification.new do |s|
  s.name        = "carrierwave-neo4j"
  s.version     = CarrierWave::Neo4j::VERSION
  s.authors     = ["Rodrigo Navarro"]
  s.email       = ["navarro@manapot.com.br"]
  s.homepage    = "https://github.com/reu/carrierwave-neo4j"
  s.summary     = %q{Neo4j support for Carrierwave}
  s.description = %q{Neo4j support for Carrierwave}

  s.rubyforge_project = "carrierwave_neo4j"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {spec}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency("activesupport", ">= 3.0" )
  s.add_dependency("neo4j", ">= 1.1")
  s.add_dependency("carrierwave", "~> 0.5")
  s.add_development_dependency("rspec", "~> 2.0")
end
