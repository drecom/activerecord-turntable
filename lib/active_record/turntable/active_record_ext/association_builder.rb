require "active_record/associations/builder/association"

module ActiveRecord::Turntable
  module ActiveRecordExt
    module AssociationBuilder
      ActiveRecord::Associations::Builder::Association::VALID_OPTIONS = [
        :class_name, :anonymous_class, :primary_key, :foreign_key, :dependent, :validate, :inverse_of, :strict_loading, :foreign_shard_key
      ].freeze
    end
  end
end
