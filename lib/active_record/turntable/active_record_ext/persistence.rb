module ActiveRecord::Turntable::ActiveRecordExt
  module Persistence
    ::ActiveRecord::Persistence.class_eval do
      def reload(options = nil)
        clear_aggregation_cache
        clear_association_cache

        ::ActiveRecord::IdentityMap.without do
          fresh_object = self.class.unscoped {
            finder_scope = if turntable_enabled? and self.class.primary_key != self.class.turntable_shard_key.to_s
                             self.class.where(self.class.turntable_shard_key => self.send(turntable_shard_key))
                           else
                             self.class
                           end
            finder_scope.find(self.id, options)
          }
          @attributes.update(fresh_object.instance_variable_get('@attributes'))
        end

        @attributes_cache = {}
        self
      end
    end

    if ActiveRecord::VERSION::STRING < '3.1'
      ::ActiveRecord::Persistence.class_eval do
        def destroy
          klass = self.class
          if persisted?
            condition_scope = klass.unscoped.where(klass.arel_table[klass.primary_key].eq(id))
            if klass.turntable_enabled? and klass.primary_key != klass.turntable_shard_key.to_s
              condition_scope = condition_scope.where(klass.turntable_shard_key => self.send(turntable_shard_key))
            end
            condition_scope.delete_all
          end

          @destroyed = true
          freeze
        end

        private

        # overrides ActiveRecord::Persistence's original method so that
        def update(attribute_names = @attributes.keys)
          klass = self.class
          attributes_with_values = arel_attributes_values(false, false, attribute_names)
          return 0 if attributes_with_values.empty?
          condition_scope = klass.unscoped.where(klass.arel_table[klass.primary_key].eq(id))
          if klass.turntable_enabled? and klass.primary_key != klass.turntable_shard_key.to_s
            condition_scope = condition_scope.where(klass.turntable_shard_key => self.send(turntable_shard_key))
          end
          condition_scope.arel.update(attributes_with_values)
        end
      end

    else
      ::ActiveRecord::Persistence.class_eval do
        def destroy
          klass = self.class
          destroy_associations

          if persisted?
            ActiveRecord::IdentityMap.remove(self) if ActiveRecord::IdentityMap.enabled?
            pk         = klass.primary_key
            column     = klass.columns_hash[pk]
            substitute = connection.substitute_at(column, 0)

            relation = klass.unscoped.where(klass.arel_table[pk].eq(substitute))
            if klass.turntable_enabled? and klass.primary_key != klass.turntable_shard_key.to_s
              relation = relation.where(klass.turntable_shard_key => self.send(turntable_shard_key))
            end
            relation.bind_values = [[column, id]]
            relation.delete_all
          end

          @destroyed = true
          freeze
        end

        def destroy_without_callbacks
          klass = self.class
          destroy_associations

          if persisted?
            ActiveRecord::IdentityMap.remove(self) if ActiveRecord::IdentityMap.enabled?
            pk         = klass.primary_key
            column     = klass.columns_hash[pk]
            substitute = connection.substitute_at(column, 0)

            relation = klass.unscoped.where(klass.arel_table[pk].eq(substitute))
            if klass.turntable_enabled? and klass.primary_key != klass.turntable_shard_key.to_s
              relation = relation.where(klass.turntable_shard_key => self.send(turntable_shard_key))
            end
            relation.bind_values = [[column, id]]
            relation.delete_all
          end

          @destroyed = true
          freeze
        end

        private
        def update(attribute_names = @attributes.keys)
          attributes_with_values = arel_attributes_values(false, false, attribute_names)
          return 0 if attributes_with_values.empty?
          klass = self.class
          condition_scope = klass.unscoped.where(klass.arel_table[klass.primary_key].eq(id))
          if klass.turntable_enabled? and klass.primary_key != klass.turntable_shard_key.to_s
            condition_scope = condition_scope.where(klass.turntable_shard_key => self.send(turntable_shard_key))
          end
          stmt = condition_scope.arel.compile_update(attributes_with_values)
          klass.connection.update stmt.to_sql
        end
      end
    end
  end
end
