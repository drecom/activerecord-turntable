module ActiveRecord::Turntable
  module ActiveRecordExt
    module Relation
      extend ActiveSupport::Concern

      included do
        if ActiveRecord::VERSION::STRING >= '4.1'
          alias_method_chain :update_record, :turntable
        end
      end

      def update_record_with_turntable(values, id, id_was, turntable_scope = nil) # :nodoc:
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
