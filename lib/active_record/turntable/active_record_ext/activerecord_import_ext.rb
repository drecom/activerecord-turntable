module ActiveRecord::Turntable
  module ActiveRecordExt
    # activerecord-import extension
    module ActiverecordImportExt
      extend ActiveSupport::Concern

      included do
        alias_method_chain :values_sql_for_columns_and_attributes, :turntable
      end

      private

        # @note override for sequencer injection
        # @see https://github.com/zdennis/activerecord-import/blob/ba909fed5a4785fe9c7cce89e48e1242bb6804ea/lib/activerecord-import/import.rb#L558-L581
        def values_sql_for_columns_and_attributes_with_turntable(columns, array_of_attributes)
          connection_memo = connection
          array_of_attributes.map do |arr|
            my_values = arr.each_with_index.map do |val, j|
              column = columns[j]

              # be sure to query sequence_name *last*, only if cheaper tests fail, because it's costly
              if val.nil? && column.name == primary_key && !sequence_name.blank?
                if sequencer_enabled?
                  connection_memo.next_sequence_value(sequence_name)
                else
                  connection_memo.next_value_for_sequence(sequence_name)
                end
              elsif column
                if respond_to?(:type_caster) && type_caster.respond_to?(:type_cast_for_database) # Rails 5.0 and higher
                  connection_memo.quote(type_caster.type_cast_for_database(column.name, val))
                elsif column.respond_to?(:type_cast_from_user)                      # Rails 4.2 and higher
                  connection_memo.quote(column.type_cast_from_user(val), column)
                else                                                                # Rails 3.1, 3.2, and 4.1
                  connection_memo.quote(column.type_cast(val), column)
                end
              end
            end
            "(#{my_values.join(',')})"
          end
        end
    end

    begin
      require "activerecord-import"
      require "activerecord-import/base"
      (class << ActiveRecord::Base; self; end).send(:include, ActiverecordImportExt)
    rescue LoadError
    end
  end
end
