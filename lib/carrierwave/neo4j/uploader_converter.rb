module CarrierWave::Neo4j
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

mod = case Neo4j::VERSION.split('.').first.to_i
        when 3 then Neo4j
        when 4 then Neo4j::Shared
      end

mod::TypeConverters.send :include, CarrierWave::Neo4j::TypeConverters