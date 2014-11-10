module ActiveRecord::Turntable
  module ActiveRecordExt
    module Relation
      extend ActiveSupport::Concern

      included do
        version = ActiveRecord::VERSION::STRING
        if version >= '4.1'
          if version < '4.1.2'
            alias_method :_update_record_without_turntable, :update_record
            alias_method :update_record, :_update_record_with_turntable
          else
            alias_method_chain :_update_record, :turntable
          end
        end
      end

      # @note Override to add sharding scope on updating
      def _update_record_with_turntable(values, id, id_was, turntable_scope = nil) # :nodoc:
        substitutes, binds = substitute_values values
        condition_scope = @klass.unscoped.where(@klass.arel_table[@klass.primary_key].eq(id_was || id))
        condition_scope = condition_scope.merge(turntable_scope) if turntable_scope
        um = condition_scope.arel.compile_update(substitutes, @klass.primary_key)

        @klass.connection.update(
          um,
          'SQL',
          binds)
      end
    end
  end
end
