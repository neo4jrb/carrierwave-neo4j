require "carrierwave/active_graph/version"
require "active_graph"
require "carrierwave"
require "carrierwave/validations/active_model"
require "carrierwave/active_graph/uploader_converter"
require "active_support/concern"

######
# This file attempts to maintain symmetry with:
# https://github.com/carrierwaveuploader/carrierwave/blob/master/lib/carrierwave/orm/activerecord.rb
# 
# Behaviours linked to callbacks (ex. `after_save :"store_#{column}!"`) belong to:
# https://github.com/carrierwaveuploader/carrierwave/blob/master/lib/carrierwave/mount.rb
# ...which is mixed into Model classes.
######
module CarrierWave
  module ActiveGraph

    # this class methods junk is necessary because ActiveNode is implemented as
    # a model instead of a class for god-knows-what-reason.
    extend ActiveSupport::Concern
    module ClassMethods

      include CarrierWave::Mount

      ##
      # See +CarrierWave::Mount#mount_uploader+ for documentation
      #
      def mount_uploader(column, uploader=nil, options={}, &block)
        super

        mod = Module.new
        prepend mod
        mod.class_eval <<-RUBY, __FILE__, __LINE__+1
          def remote_#{column}_url=(url)
            column = _mounter(:#{column}).serialization_column
            __send__(:"\#{column}_will_change!")
            super
          end
        RUBY
      end

      ##
      # See +CarrierWave::Mount#mount_uploaders+ for documentation
      #
      def mount_uploaders(column, uploader=nil, options={}, &block)
        super

        mod = Module.new
        prepend mod
        mod.class_eval <<-RUBY, __FILE__, __LINE__+1
          def remote_#{column}_urls=(url)
            column = _mounter(:#{column}).serialization_column
            __send__(:"\#{column}_will_change!")
            super
          end
        RUBY
      end

      def add_reload_callback(method)
        @_reload_callbacks = [] unless @_reload_callbacks
        @_reload_callbacks << method unless @_reload_callbacks.include?(method)
      end

      def reload_callbacks
        @_reload_callbacks
      end

    private

      def mount_base(column, uploader=nil, options={}, &block)
        super

        # this seems necessary to prevent the _identifier from including
        # the entire path ('img.jpg' vs. '/uploads/user/image/img.jpg')
        serialize column, ::CarrierWave::Uploader::Base

        include CarrierWave::Validations::ActiveModel

        validates_integrity_of column if uploader_option(column.to_sym, :validate_integrity)
        validates_processing_of column if uploader_option(column.to_sym, :validate_processing)
        validates_download_of column if uploader_option(column.to_sym, :validate_download)

        # carrierwave keeps a instance variable of @uploaders, cached at init time
        # but at init time, the value of the column is not yet available
        # so after init, the empty @uploaders cache must be invalidated
        # it will reinitialized with the processed column value on first access
        # TODO: This currently break things when initializing a model with #new and parameters. Do we need it?
        #after_initialize :_set_uploaders_nil

        before_save :"write_#{column}_identifier"
        after_save :"store_#{column}!"
        # this 'after_update' hook doesn't seem necessary, but please 
        # don't remove it just in case it ever becomes necessary:
        after_update :"mark_remove_#{column}_false"
        after_destroy :"remove_#{column}!"
        after_find :"force_retrieve_#{column}"

        add_reload_callback :"force_retrieve_#{column}"

        # TRYING THIS OUT FROM MONGOID:
        # TODO: copy the other mongoid adapter code over
        # https://github.com/carrierwaveuploader/carrierwave-mongoid/blob/master/lib/carrierwave/mongoid.rb
        before_update :"store_previous_changes_for_#{column}"
        after_save :"remove_previously_stored_#{column}"

        class_eval <<-RUBY, __FILE__, __LINE__+1

          # def remote_#{column}_url=(url) is defined in 'mount_uploader'

          def #{column}=(new_file)
            column = _mounter(:#{column}).serialization_column
            if !(new_file.blank? && __send__(:#{column}).blank?)
              __send__(:"\#{column}_will_change!")
            end
            super
          end

          def remove_#{column}=(value)
            column = _mounter(:#{column}).serialization_column
            result = super
            __send__(:"\#{column}_will_change!") if _mounter(:#{column}).remove?
            result
          end

          def remove_#{column}!
            self.remove_#{column} = true
            write_#{column}_identifier
            self.remove_#{column} = false
            super
          end

          # Reset cached mounter on record reload
          def reload(*)
            _set_uploaders_nil
            @_mounters = nil
            super
          end

          # Reset cached mounter on record dup
          def initialize_dup(other)
            _set_uploaders_nil
            @_mounters = nil
            super
          end

          def _set_uploaders_nil
            if @_mounters
              @_mounters.each do |_, mounter|
                mounter.instance_variable_set(:@uploaders, nil)
              end
            end
          end

          def _force_uploaders_reload
            @_mounters.each do |_, mounter|
              mounter.send(:uploaders)
            end
          end

          # okay, this actually works:
          def force_retrieve_#{column}
            send(:#{column}).send(:retrieve_from_store!, #{column}_identifier) if #{column}_identifier
          end

          # these produce an infinite loop, so... don't reintroduce them:
          # alias_method :read_uploader, :read_attribute
          # alias_method :write_uploader, :write_attribute
          # public :read_uploader
          # public :write_uploader
          
          def read_uploader(name)
            send(:attribute, name.to_s)
          end

          def write_uploader(name, value)
            send(:attribute=, name.to_s, value)
          end

          def reload_from_database
            if reloaded = self.class.load_entity(neo_id)
              self.class.reload_callbacks.each { |m| reloaded.send(m) }
            end
            reloaded
          end

          def reload_from_database!
            if reloaded = self.class.load_entity(neo_id)
              send(:attributes=, reloaded.attributes)
              self.class.reload_callbacks.each { |m| send(m) }
            end
            self
          end

          # MONGOID:
          # CarrierWave 1.1 references ::ActiveRecord constant directly which
          # will fail in projects without ActiveRecord. We need to overwrite this
          # method to avoid it.
          # See https://github.com/carrierwaveuploader/carrierwave/blob/07dc4d7bd7806ab4b963cf8acbad73d97cdfe74e/lib/carrierwave/mount.rb#L189
          def store_previous_changes_for_#{column}
            @_previous_changes_for_#{column} = changes[_mounter(:#{column}).serialization_column]
          end

        RUBY
      end


    end
  end
end

ActiveGraph::Node.include CarrierWave::ActiveGraph
