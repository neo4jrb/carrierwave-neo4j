module CarrierWave::Neo4j
  module TypeConverters
    class UploaderConverter
      class << self
        def convert_type
          ::CarrierWave::Uploader::Base
        end

        def to_db(value)
          if value.is_a?(Array)
            value.map(&:identifier)
          else
            value.identifier
          end
        end

        def to_ruby(value)
          value
        end
      end
    end
  end
end

def register_converter(mod)
  mod::TypeConverters.send :include, CarrierWave::Neo4j::TypeConverters
end

major = Neo4j::VERSION.split('.').first.to_i

case major
  when 1..2 then fail('Unsupported version of Neo4j gem. Please update it.')
  when 3    then register_converter(Neo4j)
  when 4    then register_converter(Neo4j::Shared)
  when 5..Float::INFINITY then Neo4j::Shared::TypeConverters.register_converter(CarrierWave::Neo4j::TypeConverters::UploaderConverter)
end
