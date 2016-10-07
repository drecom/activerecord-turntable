require "active_record/associations"

module ActiveRecord::Turntable
  module ActiveRecordExt
    module Association
      extend ActiveSupport::Concern
      include ShardingCondition

      included do
        ActiveRecord::Associations::SingularAssociation.prepend(AssociationExt)
        ActiveRecord::Associations::CollectionAssociation.prepend(AssociationExt)
        ActiveRecord::Associations::Builder::Association.valid_options += [:foreign_shard_key]
      end

      private

        def turntable_scope(scope, bind = nil)
          if should_use_shard_key?
            scope = scope.where(klass.turntable_shard_key => owner.send(foreign_shard_key))
          end
          scope
        end

        module AssociationExt
          private

          # @note Inject to add sharding condition for association
          def get_records
            # OPTIMIZE: Use bind values if cachable scope
            if should_use_shard_key?
              return turntable_scope(scope).limit(1).to_a
            end

            super
          end
        end
    end
  end
end
