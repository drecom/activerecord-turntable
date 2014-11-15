module ActiveRecord::Turntable::ActiveRecordExt
  module Persistence
    ::ActiveRecord::Persistence.class_eval do
      # @note Override to add sharding scope on reloading
      def reload(options = nil)
        clear_aggregation_cache
        clear_association_cache

        finder_scope = if turntable_enabled? and self.class.primary_key != self.class.turntable_shard_key.to_s
                         self.class.unscoped.where(self.class.turntable_shard_key => self.send(turntable_shard_key))
                       else
                         self.class.unscoped
                       end

        fresh_object =
          if options && options[:lock]
            finder_scope.lock.find(id)
          else
            finder_scope.find(id)
          end

        @attributes.update(fresh_object.instance_variable_get('@attributes'))

        @column_types           = self.class.column_types
        @column_types_override  = fresh_object.instance_variable_get('@column_types_override')
        @attributes_cache       = {}
        self
      end

      # @note Override to add sharding scope on `touch`
      def touch(name = nil)
        raise ActiveRecordError, "can not touch on a new record object" unless persisted?

        attributes = timestamp_attributes_for_update_in_model
        attributes << name if name

        unless attributes.empty?
          current_time = current_time_from_proper_timezone
          changes = {}

          attributes.each do |column|
            column = column.to_s
            changes[column] = write_attribute(column, current_time)
          end

          changes[self.class.locking_column] = increment_lock if locking_enabled?

          @changed_attributes.except!(*changes.keys)
          primary_key = self.class.primary_key

          finder_scope = if turntable_enabled? and primary_key != self.class.turntable_shard_key.to_s
                           self.class.unscoped.where(self.class.turntable_shard_key => self.send(turntable_shard_key))
                         else
                           self.class.unscoped
                         end

          finder_scope.where(primary_key => self[primary_key]).update_all(changes) == 1
        end

        # @note Override to add sharding scope on `update_columns`
        def update_columns(attributes)
          raise ActiveRecordError, "cannot update on a new record object" unless persisted?

          attributes.each_key do |key|
            verify_readonly_attribute(key.to_s)
          end

          update_scope = if turntable_enabled? and self.class.primary_key != self.class.turntable_shard_key.to_s
                           self.class.unscoped.where(self.class.turntable_shard_key => self.send(turntable_shard_key))
                         else
                           self.class.unscoped
                         end

          updated_count = update_scope.where(self.class.primary_key => id).update_all(attributes)

          attributes.each do |k, v|
            raw_write_attribute(k, v)
          end

          updated_count == 1
        end
      end

      private

      # @note Override to add sharding scope on destroying
      def relation_for_destroy
        pk         = self.class.primary_key
        column     = self.class.columns_hash[pk]
        substitute = self.class.connection.substitute_at(column, 0)
        klass      = self.class

        relation = self.class.unscoped.where(
          self.class.arel_table[pk].eq(substitute))
        if klass.turntable_enabled? and klass.primary_key != klass.turntable_shard_key.to_s
          relation = relation.where(klass.turntable_shard_key => self.send(turntable_shard_key))
        end

        relation.bind_values = [[column, id]]
        relation
      end


      # @note Override to add sharding scope on updating
      ar_version = ActiveRecord::VERSION::STRING
      if ar_version < "4.1"
        method_name = ar_version =~ /\A4\.0\.[0-5]\z/ ? "update_record" : "_update_record"
        class_eval <<-EOD
          def #{method_name}(attribute_names = @attributes.keys)
            attributes_with_values = arel_attributes_with_values_for_update(attribute_names)
            if attributes_with_values.empty?
              0
            else
              klass = self.class
              column_hash = klass.connection.schema_cache.columns_hash klass.table_name
              db_columns_with_values = attributes_with_values.map { |attr,value|
                real_column = column_hash[attr.name]
                [real_column, value]
              }
              bind_attrs = attributes_with_values.dup
              bind_attrs.keys.each_with_index do |column, i|
                real_column = db_columns_with_values[i].first
                bind_attrs[column] = klass.connection.substitute_at(real_column, i)
              end
              condition_scope = klass.unscoped.where(klass.arel_table[klass.primary_key].eq(id_was || id))
              if klass.turntable_enabled? and klass.primary_key != klass.turntable_shard_key.to_s
                condition_scope = condition_scope.where(klass.turntable_shard_key => self.send(turntable_shard_key))
              end
              stmt = condition_scope.arel.compile_update(bind_attrs)
              klass.connection.update stmt, 'SQL', db_columns_with_values
            end
          end
        EOD
      else
        method_name = ar_version =~ /\A4\.1\.[01]\z/ ? "update_record" : "_update_record"
        class_eval <<-EOD
          def #{method_name}(attribute_names = @attributes.keys)
            klass = self.class
            attributes_values = arel_attributes_with_values_for_update(attribute_names)
            if attributes_values.empty?
              0
            else
              scope = if klass.turntable_enabled? and klass.primary_key != klass.turntable_shard_key.to_s
                klass.unscoped.where(klass.turntable_shard_key => self.send(turntable_shard_key))
              end
              klass.unscoped.#{method_name} attributes_values, id, id_was, scope
            end
          end
        EOD
      end
    end
  end
end
