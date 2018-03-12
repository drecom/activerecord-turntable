module ActiveRecord::Turntable
  module ShardingCondition
    private

      def foreign_shard_key
        reflection.options[:foreign_shard_key] || foreign_target_model.turntable_shard_key
      end

      def foreign_target_model
        return model if respond_to?(:model)
        return @model if @model
        owner
      end

      def should_use_shard_key?
        sharded_by_same_key? || !!reflection.options[:foreign_shard_key]
      end

      def sharded_by_same_key?
        foreign_target_model.turntable_enabled? &&
          klass.turntable_enabled? &&
          foreign_shard_key == klass.turntable_shard_key
      end
  end
end
