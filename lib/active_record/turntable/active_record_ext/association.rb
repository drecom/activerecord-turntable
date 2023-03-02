require "active_record/associations"

module ActiveRecord::Turntable
  module ActiveRecordExt
    module Association
      include ShardingCondition

      unless Util.ar61_or_later?
        def self.prepended(mod)
          ActiveRecord::Associations::Builder::Association::VALID_OPTIONS << :foreign_shard_key
        end
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

        if Util.ar52_or_later?
          def skip_statement_cache?(scope)
            super || should_use_shard_key?
          end
        else
          def skip_statement_cache?
            super || should_use_shard_key?
          end
        end
    end
  end
end
