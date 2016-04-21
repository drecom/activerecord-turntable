module ActiveRecord::Turntable
  module ActiveRecordExt
    module Relation
      extend ActiveSupport::Concern

      included do
        if Util.ar41_or_later?
          if Util.ar_version_earlier_than?("4.1.2")
            alias_method :_update_record_without_turntable, :update_record
            alias_method :update_record, :_update_record_with_turntable
          else
            alias_method_chain :_update_record, :turntable
          end
        end
      end

      # @note Override to add sharding scope on updating
      if Util.ar42_or_later?
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
      else
        def _update_record_with_turntable(values, id, id_was, turntable_scope = nil) # :nodoc:
          substitutes, binds = substitute_values values
          condition_scope = @klass.unscoped.where(@klass.arel_table[@klass.primary_key].eq(id_was || id))
          condition_scope = condition_scope.merge(turntable_scope) if turntable_scope
          um = condition_scope.arel.compile_update(substitutes, @klass.primary_key)

          @klass.connection.update(
            um,
            "SQL",
            binds)
        end
      end
    end
  end
end
