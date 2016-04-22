require "active_record/associations/preloader/association"

module ActiveRecord::Turntable
  module ActiveRecordExt
    module AssociationPreloader
      # @note Override to add sharding condition on preload
      def records_for(ids)
        returning_scope = super
        if should_use_shard_key?
          returning_scope = returning_scope.where(klass.turntable_shard_key => owners.map(&foreign_shard_key.to_sym).uniq)
        end
        returning_scope
      end

      private

        def foreign_shard_key
          options[:foreign_shard_key] || model.turntable_shard_key
        end

        def should_use_shard_key?
          sharded_by_same_key? || !!options[:foreign_shard_key]
        end

        def sharded_by_same_key?
          model.turntable_enabled? &&
            klass.turntable_enabled? &&
            model.turntable_shard_key == klass.turntable_shard_key
        end
    end
  end
end
