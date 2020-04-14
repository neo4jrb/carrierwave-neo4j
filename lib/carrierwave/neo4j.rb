require "carrierwave/neo4j/version"
require "neo4j"
require "carrierwave"
require "carrierwave/validations/active_model"
require "carrierwave/neo4j/uploader_converter"
require "active_support/concern"

######
# This file attempts to maintain symmetry with:
# https://github.com/carrierwaveuploader/carrierwave/blob/master/lib/carrierwave/orm/activerecord.rb
# 
# Behaviours linked to callbacks (ex. `after_save :"store_#{column}!"`) belong to:
# https://github.com/carrierwaveuploader/carrierwave/blob/master/lib/carrierwave/mount.rb
######
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
        validates_download_of column if uploader_option(column.to_sym, :validate_download)

        before_save :"write_#{column}_identifier"
        after_save :"store_#{column}!"
        after_destroy_commit :"remove_#{column}!"

        # TODO: these come next; write tests first
        # after_update_commit :"mark_remove_#{column}_false"
        # after_update_commit :"remove_previously_stored_#{column}"
        # after_update_commit :"store_#{column}!"
        # after_create_commit :"store_#{column}!"

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

        # carrierwave keeps a instance variable of @uploaders, cached at init time
        # but at init time, the value of the column is not yet available
        # so after init, the empty @uploaders cache must be invalidated
        # it will reinitialized with the processed column value on first access
        unless method_defined?(:_set_uploaders_nil)

          after_initialize :_set_uploaders_nil

          def _set_uploaders_nil
            if @_mounters
              @_mounters.each do |_, mounter|
                mounter.instance_variable_set(:@uploaders, nil)
              end
            end
          end
        end
        RUBY
      end
    end

  end
end

Neo4j::ActiveNode.send :include, CarrierWave::Neo4j
