require "active_record/associations"

module ActiveRecord::Turntable
  module ActiveRecordExt
    module Association
      include ShardingCondition

      def self.prepended(mod)
        ActiveRecord::Associations::Builder::Association::VALID_OPTIONS << :foreign_shard_key
      end

      protected

        # @note Override to pass shard key conditions
        def target_scope
          return super unless should_use_shard_key?

          scope = klass.where(
                    klass.turntable_shard_key =>
                      owner.send(foreign_shard_key)
                  )
          super.merge!(scope)
        end

      private

        def skip_statement_cache?
          super || should_use_shard_key?
        end
    end
  end
end
