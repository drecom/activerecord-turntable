require "active_record/associations"

module ActiveRecord::Turntable
  module ActiveRecordExt
    module Association
      extend ActiveSupport::Concern
      include ShardingCondition

      included do
        ActiveRecord::Associations::SingularAssociation.prepend(SingularAssociationExt)
        ActiveRecord::Associations::CollectionAssociation.prepend(CollectionAssociationExt)
        ActiveRecord::Associations::Builder::Association::VALID_OPTIONS << :foreign_shard_key
      end

      # @note Inject to add sharding condition for singular association
      module SingularAssociationExt
        private
          def get_records
            # OPTIMIZE: statement caching
            if should_use_shard_key?
              return turntable_scope(scope).limit(1).records
            end

            super
          end
      end

      # @note Inject to add sharding condition for collection association
      module CollectionAssociationExt
        private
          def get_records
            # OPTIMIZE: statement caching
            if should_use_shard_key?
              return turntable_scope(scope).to_a
            end

            super
          end
      end

      private

        def turntable_scope(scope, bind = nil)
          if should_use_shard_key?
            scope = scope.where(klass.turntable_shard_key => owner.send(foreign_shard_key))
          end
          scope
        end
    end
  end
end
