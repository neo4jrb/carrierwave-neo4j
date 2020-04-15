## CarrierWave for Neo4j

This gem adds support for Neo4j 3.0+ (neo4j.rb 9.6.0+) to CarrierWave 2.1.0+, see the CarrierWave documentation for more detailed usage instructions.

### Installation Instructions

Add to your Gemfile:

```ruby
gem 'carrierwave-neo4j', require: 'carrierwave/neo4j'
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
  include Neo4j::ActiveNode

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
rake spec
```

### Troubleshooting

If you're getting some infinite recursion when you run the specs that ultimately results in an error like:

```
`ensure in require': CRITICAL: RUBYGEMS_ACTIVATION_MONITOR.owned?: before false -> after true (RuntimeError)
```

You may want to try:

```sh
rm .bundle/config
bundle install
```
