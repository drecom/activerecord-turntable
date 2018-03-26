module ActiveRecord::Turntable
  module ActiveRecordExt
    module Persistence
      extend ActiveSupport::Concern
      extend Compatibility

      if Util.ar52_or_later?
        ::ActiveRecord::Persistence::ClassMethods.class_eval do
          # @note Override to add sharding scope on updating
          def _update_record(values, id, id_was, turntable_scope = nil) # :nodoc:
          bind = predicate_builder.build_bind_attribute(primary_key, id_was || id)
          relation = arel_table.where(
            arel_attribute(primary_key).eq(bind)
          )
          if turntable_scope
            relation = relation.where(turntable_scope)
          end
          um = relation.compile_update(_substitute_values(values), primary_key)

          connection.update(um, "#{self} Update")
          end
        end
      end

      ::ActiveRecord::Persistence.class_eval do
        # @note Override to add sharding scope on reloading
        def reload(options = nil)
          self.class.connection.clear_query_cache

          finder_scope = if turntable_enabled? && self.class.primary_key != self.class.turntable_shard_key.to_s
                           self.class.unscoped.where(self.class.turntable_shard_key => self.send(turntable_shard_key))
                         else
                           self.class.unscoped
                         end

          fresh_object =
            if options && options[:lock]
              finder_scope.lock(options[:lock]).find(id)
            else
              finder_scope.find(id)
            end

          @attributes = fresh_object.instance_variable_get("@attributes")
          @new_record = false
          self
        end

        unless Util.ar_version_equals_or_later?("5.1.6")
          # @note Override to add sharding scope on `touch`
          # rubocop:disable Style/UnlessElse
          def touch(*names, time: nil)
            unless persisted?
              raise ActiveRecord::ActiveRecordError, <<-MSG.squish
                cannot touch on a new or destroyed record object. Consider using
                persisted?, new_record?, or destroyed? before touching
              MSG
            end

            time ||= current_time_from_proper_timezone
            attributes = timestamp_attributes_for_update_in_model
            attributes.concat(names)

            unless attributes.empty?
              changes = {}

              attributes.each do |column|
                column = column.to_s
                changes[column] = write_attribute(column, time)
              end

              clear_attribute_changes(changes.keys) unless Util.ar51_or_later?
              primary_key = self.class.primary_key
              scope = if turntable_enabled? && primary_key != self.class.turntable_shard_key.to_s
                        self.class.unscoped.where(self.class.turntable_shard_key => _read_attribute(turntable_shard_key))
                      else
                        self.class.unscoped
                      end
              scope = scope.where(primary_key => _read_attribute(primary_key))

              if locking_enabled?
                locking_column = self.class.locking_column
                scope = scope.where(locking_column => _read_attribute(locking_column))
                changes[locking_column] = increment_lock
              end

              clear_attribute_changes(changes.keys) if Util.ar51_or_later?
              result = scope.update_all(changes) == 1

              if !result && locking_enabled?
                raise ActiveRecord::StaleObjectError.new(self, "touch")
              end

              @_trigger_update_callback = result
              result
            else
              true
            end
          end
          # rubocop:enable Style/UnlessElse
        end

        # @note Override to add sharding scope on `update_columns`
        unless Util.ar52_or_later?
          def update_columns(attributes)
            raise ActiveRecord::ActiveRecordError, "cannot update a new record" if new_record?
            raise ActiveRecord::ActiveRecordError, "cannot update a destroyed record" if destroyed?

            attributes.each_key do |key|
              verify_readonly_attribute(key.to_s)
            end

            update_scope = if turntable_enabled? && self.class.primary_key != self.class.turntable_shard_key.to_s
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
          unless Util.ar52_or_later?
            def relation_for_destroy
              klass = self.class
              relation = klass.unscoped.where(klass.primary_key => id)

              if klass.turntable_enabled? && klass.primary_key != klass.turntable_shard_key.to_s
                relation = relation.where(klass.turntable_shard_key => self[klass.turntable_shard_key])
              end
              relation
            end
          end

          if Util.ar52_or_later?
            def _relation_for_itself
              klass = self.class
              relation = klass.unscoped.where(klass.primary_key => id)
              unless klass.turntable_enabled? && klass.primary_key != klass.turntable_shard_key.to_s
                return relation
              end

              relation.where(klass.turntable_shard_key => self[klass.turntable_shard_key])
            end

            def _update_record(attribute_names = self.attribute_names)
              attributes_values = arel_attributes_with_values_for_update(attribute_names)
              if attributes_values.empty?
                rows_affected = 0
                @_trigger_update_callback = true
              else
                klass = self.class
                scope = if klass.turntable_enabled? && (klass.primary_key != klass.turntable_shard_key.to_s)
                          klass.arel_attribute(klass.turntable_shard_key).eq(self.send(turntable_shard_key))
                        end
                rows_affected = klass._update_record(attributes_values, id, id_in_database, scope)
                @_trigger_update_callback = rows_affected > 0
              end

              yield(self) if block_given?

              rows_affected
            end
          elsif Util.ar_version_equals_or_later?("5.1.6")
            def _update_row(attribute_names, attempted_action = "update")
              constraints = { self.class.primary_key => id_in_database }
              if self.class.sharding_condition_needed?
                constraints[self.class.turntable_shard_key] = self[self.class.turntable_shard_key]
              end

              self.class.unscoped._update_record(
                arel_attributes_with_values(attribute_names),
                constraints,
              )
            end
          else
            # @note Override to add sharding scope on updating
            def _update_record(attribute_names = self.attribute_names)
              klass = self.class
              attributes_values = arel_attributes_with_values_for_update(attribute_names)
              if attributes_values.empty?
                rows_affected = 0
                @_trigger_update_callback = true
              else
                scope = if klass.turntable_enabled? && (klass.primary_key != klass.turntable_shard_key.to_s)
                          klass.unscoped.where(klass.turntable_shard_key => self.send(turntable_shard_key))
                        end
                previous_id = Util.ar51_or_later? ? id_in_database : id_was
                rows_affected = klass.unscoped._update_record attributes_values, id, previous_id, scope
                @_trigger_update_callback = rows_affected > 0
              end

              yield(self) if block_given?

              rows_affected
            end
          end
      end
    end
  end
end
