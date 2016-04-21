require "active_record/associations"

module ActiveRecord::Turntable
  module ActiveRecordExt
    module Association
      extend ActiveSupport::Concern

      included do
        ActiveRecord::Associations::SingularAssociation.send(:include, SingularAssociationExt)
        ActiveRecord::Associations::CollectionAssociation.send(:include, CollectionAssociationExt)
        ActiveRecord::Associations::Builder::Association.valid_options += [:foreign_shard_key]
      end

      private

        def turntable_scope(scope, bind = nil)
          if should_use_shard_key?
            scope = scope.where(klass.turntable_shard_key => owner.send(foreign_shard_key))
          end
          scope
        end

        module SingularAssociationExt
          extend ActiveSupport::Concern

          included do
            if Util.ar42_or_later?
              alias_method_chain :get_records, :turntable
            else
              alias_method_chain :find_target, :turntable
            end
          end

          # @note Override to add sharding condition for singular association
          if Util.ar42_or_later?
            def get_records_with_turntable
              if reflection.scope_chain.any?(&:any?) ||
                 scope.eager_loading? ||
                 klass.current_scope ||
                 klass.default_scopes.any? ||
                 should_use_shard_key? # OPTIMIZE: Use bind values if cachable scope

                return turntable_scope(scope).limit(1).to_a
              end

              conn = klass.connection
              sc = reflection.association_scope_cache(conn, owner) do
                ActiveRecord::StatementCache.create(conn) { |params|
                  as = ActiveRecord::Associations::AssociationScope.create { params.bind }
                  target_scope.merge(as.scope(self, conn)).limit(1)
                }
              end

              binds = ActiveRecord::Associations::AssociationScope.get_bind_values(owner, reflection.chain)
              sc.execute binds, klass, klass.connection
            end
          elsif Util.ar41_or_later?
            def find_target_with_turntable
              if record = turntable_scope(scope).take
                set_inverse_instance record
              end
            end
          else
            def find_target_with_turntable
              turntable_scope(scope).take.tap { |record| set_inverse_instance(record) }
            end
          end
        end

        module CollectionAssociationExt
          extend ActiveSupport::Concern

          included do
            if Util.ar42_or_later?
              alias_method_chain :get_records, :turntable
            else
              alias_method_chain :find_target, :turntable
            end
          end

          private

            if Util.ar42_or_later?
              def get_records_with_turntable
                if reflection.scope_chain.any?(&:any?) ||
                   scope.eager_loading? ||
                   klass.current_scope ||
                   klass.default_scopes.any? ||
                   should_use_shard_key? # OPTIMIZE: Use bind values if cachable scope

                  return turntable_scope(scope).to_a
                end

                conn = klass.connection
                sc = reflection.association_scope_cache(conn, owner) do
                  ActiveRecord::StatementCache.create(conn) { |params|
                    as = ActiveRecord::Associations::AssociationScope.create { params.bind }
                    target_scope.merge as.scope(self, conn)
                  }
                end

                binds = ActiveRecord::Associations::AssociationScope.get_bind_values(owner, reflection.chain)
                sc.execute binds, klass, klass.connection
              end
            else
              # @note Override to add sharding condition for collection association
              def find_target_with_turntable
                records =
                  if options[:finder_sql]
                    reflection.klass.find_by_sql(custom_finder_sql)
                  else
                    current_scope = scope
                    if should_use_shard_key?
                      current_scope = current_scope.where(klass.turntable_shard_key => owner.send(foreign_shard_key))
                    end
                    current_scope.to_a
                  end
                records.each { |record| set_inverse_instance(record) }
                records
              end
            end
        end

      private

        def foreign_shard_key
          options[:foreign_shard_key] || owner.turntable_shard_key
        end

        def should_use_shard_key?
          same_association_shard_key? || !!options[:foreign_shard_key]
        end

        def same_association_shard_key?
          owner.class.turntable_enabled? && klass.turntable_enabled? && foreign_shard_key == klass.turntable_shard_key
        end
    end
  end
end
