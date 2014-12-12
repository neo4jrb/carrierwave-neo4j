## CarrierWave for Neo4j

This gem adds support for Neo4j 3.0+ to CarrierWave, see the CarrierWave documentation for more detailed usage instructions.

### Installation Instructions

Add to your Gemfile:

```ruby
gem 'carrierwave-neo4j', require: 'carrierwave/neo4j', github: 'dpisarewski/carrierwave-neo4j'
```
Use it like this:

```ruby
class Asset
  include Neo4j::ActiveNode
  extend CarrierWave::Neo4j

  property :attachment, type: String
  mount_uploader :attachment, AttachmentUploader
end
```