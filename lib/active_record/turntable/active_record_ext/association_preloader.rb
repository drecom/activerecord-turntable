require 'active_record/associations/preloader/association'

module ActiveRecord::Turntable
  module ActiveRecordExt
    module AssociationPreloader
      extend ActiveSupport::Concern

      included do
        alias_method_chain :records_for, :turntable
      end

      def records_for_with_turntable(ids)
        returning_scope = records_for_without_turntable(ids)
        if sharded_by_same_key? && owners_have_same_shard_key?
          returning_scope = returning_scope.where(klass.turntable_shard_key => owners.first.send(klass.turntable_shard_key))
        end
        returning_scope
      end

      private

      def sharded_by_same_key?
        model.turntable_enabled? &&
          klass.turntable_enabled? &&
          model.turntable_shard_key == klass.turntable_shard_key
      end

      def owners_have_same_shard_key?
        owners.map(&klass.turntable_shard_key).uniq.size == 1
      end
    end
  end
end
