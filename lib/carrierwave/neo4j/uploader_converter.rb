module Neo4j::Shared
  module TypeConverters
    class UploaderConverter
      class << self
        def convert_type
          ::CarrierWave::Uploader::Base
        end

        def to_db(value)
          value.identifier
        end

        def to_ruby(value)
          value
        end
      end
    end
  end
end