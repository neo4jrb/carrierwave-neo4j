# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "carrierwave/active_graph/version"

Gem::Specification.new do |s|
  s.name        = "carrierwave-activegraph"
  s.version     = CarrierWave::ActiveGraph::VERSION
  s.authors     = ["Rodrigo Navarro"]
  s.email       = ["navarro@manapot.com.br"]
  s.homepage    = "https://github.com/neo4jrb/carrierwave-neo4j"
  s.summary     = %q{Neo4j support for Carrierwave}
  s.description = %q{Neo4j support for Carrierwave}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {spec}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency("activesupport", ">= 6.0" )
  s.add_dependency("activegraph", ">= 10.0.0")
  s.add_dependency("carrierwave", ">= 2.1")
  s.add_development_dependency("neo4j-#{ENV['driver'] == 'java' ? 'java' : 'ruby'}-driver", '~> 1.7.4')
  s.add_development_dependency("rspec", "~> 3.0")
  s.add_development_dependency("rspec-its")
  s.add_development_dependency("webmock")
  s.add_development_dependency("neo4j-rake_tasks")
  s.add_development_dependency("rake")
end
