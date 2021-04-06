## CarrierWave for Neo4j

This gem adds support for Neo4j 3.0+ (neo4j.rb 9.6.0+) to CarrierWave 2.1.0+, see the CarrierWave documentation for more detailed usage instructions.

### Installation Instructions

Add to your Gemfile:

```ruby
gem 'carrierwave-neo4j', '~> 3.0', require: 'carrierwave/neo4j'
```

You can see example usage in `spec/neo4j_realistic_spec.rb` but in brief, you can use it like this:

```ruby
class AttachmentUploader < CarrierWave::Uploader::Base
  storage :file

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end
end

class Asset
  include ActiveGraph::Node

  property :attachment, type: String
  mount_uploader :attachment, AttachmentUploader
end
```

If you want image manipulation, you will need to install ImageMagick

On Ubuntu:

```sh
sudo apt-get install imagemagick --fix-missing
```

On macOS:

```sh
brew install imagemagick
```

### Development

```sh
bundle install
rake neo4j:install[community-4.0.11,test]
rake neo4j:start[test]
rake spec
```

### Troubleshooting

#### Files are nil

If you aren't getting your files back after querying a record from Neo4j, be aware that this will only happen automatically for the `Model#find` method. For all other finders (`#all`, `#first`, `#find_by`, `#find_by_*`, `#find_by_*!`, `#last`) you will need to force a reload so the model sees the file. For example:

```ruby
users = User.all
users.each(&:reload_from_database!)
```

Sorry, this sucks. But this is a limitation of Neo4j.rb as these other finders don't fire any callbacks.

#### binstubs (particularly `bin/rspec`) seem broken

If you're getting some infinite recursion when you run the specs that ultimately results in an error like:

```
`ensure in require': CRITICAL: RUBYGEMS_ACTIVATION_MONITOR.owned?: before false -> after true (RuntimeError)
```

You may want to try:

```sh
rm .bundle/config
bundle install
```
