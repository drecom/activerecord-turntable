module ActiveRecord::Turntable
  module ActiveRecordExt
    module Relation
      # @note Override to add sharding scope on updating
      def _update_record(values, id, id_was, turntable_scope = nil) # :nodoc:
        substitutes, binds = substitute_values values

        scope = @klass.unscoped

        if @klass.finder_needs_type_condition?
          scope.unscope!(where: @klass.inheritance_column)
        end

        relation = scope.where(@klass.primary_key => (id_was || id))
        relation = relation.merge(turntable_scope) if turntable_scope
        bvs = binds + relation.bound_attributes
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
