module ActiveRecord::Turntable
  module ActiveRecordExt
    module Relation
      extend ActiveSupport::Concern

      included do
        alias_method_chain :_update_record, :turntable
      end

      # @note Override to add sharding scope on updating
      def _update_record_with_turntable(values, id, id_was, turntable_scope = nil) # :nodoc:
        substitutes, binds = substitute_values values

        scope = @klass.unscoped

        if @klass.finder_needs_type_condition?
          scope.unscope!(where: @klass.inheritance_column)
        end

        relation = scope.where(@klass.primary_key => (id_was || id))
        relation = relation.merge(turntable_scope) if turntable_scope

        bvs = binds + relation.bind_values
        um = relation.
             arel.
             compile_update(substitutes, @klass.primary_key)

        @klass.connection.update(
          um,
          "SQL",
          bvs
        )
      end
    end
  end
end
