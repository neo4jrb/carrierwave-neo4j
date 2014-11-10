require "carrierwave/neo4j/version"
require "neo4j"
require "carrierwave"
require "carrierwave/validations/active_model"

module CarrierWave
  module Neo4j
    include CarrierWave::Mount

    ##
    # See +CarrierWave::Mount#mount_uploader+ for documentation
    #
    def mount_uploader(column, uploader = nil, options = {}, &block)
      property column

      super

      alias_method :read_uploader, :read_attribute
      alias_method :write_uploader, :write_attribute

      include CarrierWave::Validations::ActiveModel

      validates_integrity_of  column if uploader_option(column.to_sym, :validate_integrity)
      validates_processing_of column if uploader_option(column.to_sym, :validate_processing)

      after_save :"store_#{column}!"
      before_save :"write_#{column}_identifier"
      after_destroy :"remove_#{column}!"

      class_eval <<-RUBY, __FILE__, __LINE__+1
        def _mounter(column)
          @_mounters ||= {}
          @_mounters[column] ||= CarrierWave::Mount::Mounter.new(self, column)
        end
      RUBY
    end
  end
end
