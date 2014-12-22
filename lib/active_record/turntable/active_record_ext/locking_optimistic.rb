module ActiveRecord::Turntable::ActiveRecordExt
  module LockingOptimistic
    # @note Override to add sharding condition on optimistic locking
    ::ActiveRecord::Locking::Optimistic.class_eval do

      ar_version = ActiveRecord::VERSION::STRING
      if ar_version < "4.1"
        method_name = ar_version =~ /\A4\.0\.[0-5]\z/ ? "update_record" : "_update_record"

        class_eval <<-EOD
          def #{method_name}(attribute_names = @attributes.keys) #:nodoc:
            return super unless locking_enabled?
            return 0 if attribute_names.empty?

            klass = self.class
            lock_col = self.class.locking_column
            previous_lock_value = send(lock_col).to_i
            increment_lock

            attribute_names += [lock_col]
            attribute_names.uniq!

            begin
              relation = self.class.unscoped

              condition_scope = relation.where(
                relation.table[self.class.primary_key].eq(id).and(
                  relation.table[lock_col].eq(self.class.quote_value(previous_lock_value, column_for_attribute(lock_col)))
                )
              )
              if klass.turntable_enabled? and klass.primary_key != klass.turntable_shard_key.to_s
                condition_scope = condition_scope.where(
                  relation.table[klass.turntable_shard_key].eq(
                     self.class.quote_value(self.send(turntable_shard_key), column_for_attribute(klass.turntable_shard_key))
                  )
                )
              end
              stmt = condition_scope.arel.compile_update(arel_attributes_with_values_for_update(attribute_names))

              affected_rows = self.class.connection.update stmt

              unless affected_rows == 1
                raise ActiveRecord::StaleObjectError.new(self, "update")
              end

              affected_rows

            # If something went wrong, revert the version.
            rescue Exception
              send(lock_col + '=', previous_lock_value)
              raise
            end
          end
        EOD
      else
        method_name = ar_version =~ /\A4\.1\.[01]\z/ ? "update_record" : "_update_record"

        class_eval <<-EOD
          def _update_record(attribute_names = @attributes.keys) #:nodoc:
            return super unless locking_enabled?
            return 0 if attribute_names.empty?

            klass = self.class
            lock_col = self.class.locking_column
            previous_lock_value = send(lock_col).to_i
            increment_lock

            attribute_names += [lock_col]
            attribute_names.uniq!

            begin
              relation = self.class.unscoped

              condition_scope = relation.where(
                relation.table[self.class.primary_key].eq(id).and(
                  relation.table[lock_col].eq(self.class.quote_value(previous_lock_value, column_for_attribute(lock_col)))
                )
              )
              if klass.turntable_enabled? and klass.primary_key != klass.turntable_shard_key.to_s
                condition_scope = condition_scope.where(
                  relation.table[klass.turntable_shard_key].eq(
                     self.class.quote_value(self.send(turntable_shard_key), column_for_attribute(klass.turntable_shard_key))
                  )
                )
              end
              stmt = condition_scope.arel.compile_update(
                       arel_attributes_with_values_for_update(attribute_names),
                       self.class.primary_key
                     )

              affected_rows = self.class.connection.update stmt

              unless affected_rows == 1
                raise ActiveRecord::StaleObjectError.new(self, "update")
              end

              affected_rows

            # If something went wrong, revert the version.
            rescue Exception
              send(lock_col + '=', previous_lock_value)
              raise
            end
          end
        EOD
      end
    end
  end
end
