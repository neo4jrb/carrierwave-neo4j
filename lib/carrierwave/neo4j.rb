require "carrierwave/neo4j/version"
require "neo4j"
require "carrierwave"
require "carrierwave/validations/active_model"
require "carrierwave/neo4j/uploader_converter"
require "active_support/concern"

module CarrierWave
  module Neo4j
    extend ActiveSupport::Concern

    module ClassMethods
      include CarrierWave::Mount
      ##
      # See +CarrierWave::Mount#mount_uploader+ for documentation
      #
      def mount_uploader(column, uploader = nil, options = {}, &block)
        super

        serialize column, ::CarrierWave::Uploader::Base

        include CarrierWave::Validations::ActiveModel

        validates_integrity_of  column if uploader_option(column.to_sym, :validate_integrity)
        validates_processing_of column if uploader_option(column.to_sym, :validate_processing)

        after_save :"store_#{column}!"
        before_save :"write_#{column}_identifier"
        before_destroy :"clear_#{column}"
        after_destroy :"remove_#{column}!"

        class_eval <<-RUBY, __FILE__, __LINE__+1
        def #{column}=(new_file)
          column = _mounter(:#{column}).serialization_column
          send(:attribute_will_change!, :#{column})
          super
        end

        def remote_#{column}_url=(url)
          column = _mounter(:#{column}).serialization_column
          send(:attribute_will_change!, :#{column})
          super
        end

        def clear_#{column}
          write_uploader(_mounter(:#{column}).serialization_column, nil)
        end

        def _mounter(column)
          @_mounters ||= {}
          mounter_class = defined?(CarrierWave::Mounter) ? CarrierWave::Mounter : CarrierWave::Mount::Mounter
          @_mounters[column] ||= mounter_class.new(self, column)
        end

        def read_uploader(name)
          send(:attribute, name.to_s)
        end

        def write_uploader(name, value)
          send(:attribute=, name.to_s, value)
        end

        def reload_from_database
          if reloaded = self.class.load_entity(neo_id)
            send(:attributes=, reloaded.attributes.reject{ |k,v| v.is_a?(::CarrierWave::Uploader::Base) })
          end
          reloaded
        end
        RUBY
      end
    end

  end
end

Neo4j::ActiveNode.send :include, CarrierWave::Neo4j
