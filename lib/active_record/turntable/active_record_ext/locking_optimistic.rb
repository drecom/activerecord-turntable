module ActiveRecord::Turntable
  module ActiveRecordExt
    module LockingOptimistic
      if Util.ar_version_equals_or_later?("5.1.6")
        ::ActiveRecord::Locking::Optimistic.class_eval <<-EOD
          private
          def _update_row(attribute_names, attempted_action = "update")
            return super unless locking_enabled?

            begin
              locking_column = self.class.locking_column
              previous_lock_value = read_attribute_before_type_cast(locking_column)
              attribute_names << locking_column

              self[locking_column] += 1

              constraints = {
                self.class.primary_key => id_in_database,
                locking_column => previous_lock_value
              }
              if self.class.sharding_condition_needed?
                constraints[self.class.turntable_shard_key] = self[self.class.turntable_shard_key]
              end

              affected_rows = self.class.unscoped._update_record(
                arel_attributes_with_values(attribute_names),
                constraints,
              )

              if affected_rows != 1
                raise ActiveRecord::StaleObjectError.new(self, attempted_action)
              end

              affected_rows

            # If something went wrong, revert the locking_column value.
            rescue Exception
              self[locking_column] = previous_lock_value.to_i
              raise
            end
          end
        EOD
      elsif Util.ar51?
        ::ActiveRecord::Locking::Optimistic.class_eval <<-EOD
          private
          # @note Override to add sharding condition on optimistic locking
          def _update_record(attribute_names = self.attribute_names)
            return super unless locking_enabled?
            return 0 if attribute_names.empty?

            begin
              klass = self.class

              lock_col = self.class.locking_column

              previous_lock_value = read_attribute_before_type_cast(lock_col)

              increment_lock

              attribute_names.push(lock_col)

              relation = self.class.unscoped

              condition_scope = relation.where(
                self.class.primary_key => id,
                lock_col => previous_lock_value
              )
              if klass.turntable_enabled? and klass.primary_key != klass.turntable_shard_key.to_s
                condition_scope = condition_scope.where(
                  klass.turntable_shard_key => self.send(klass.turntable_shard_key)
                )
              end

              affected_rows = condition_scope.update_all(
                attributes_for_update(attribute_names).map do |name|
                  [name, _read_attribute(name)]
                end.to_h
              )

              unless affected_rows == 1
                raise ActiveRecord::StaleObjectError.new(self, "update")
              end

              affected_rows

            # If something went wrong, revert the locking_column value.
            rescue Exception
              send(lock_col + "=", previous_lock_value.to_i)
              raise
            end
          end
        EOD
      elsif Util.earlier_than_ar51?
        ::ActiveRecord::Locking::Optimistic.class_eval <<-EOD
          private
          # @note Override to add sharding condition on optimistic locking
          def _update_record(attribute_names = self.attribute_names) #:nodoc:
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
                self.class.primary_key => id,
                lock_col => previous_lock_value,
              )
              if klass.turntable_enabled? and klass.primary_key != klass.turntable_shard_key.to_s
                condition_scope = condition_scope.where(
                  klass.turntable_shard_key => self.send(klass.turntable_shard_key)
                )
              end

              affected_rows = condition_scope.update_all(
                attributes_for_update(attribute_names).map do |name|
                  [name, _read_attribute(name)]
                end.to_h
              )

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
