module ActiveRecord::Turntable
  module ActiveRecordExt
    # activerecord-import extension
    module ActiverecordImportExt
      # @note override for sequencer injection
      # @see https://github.com/zdennis/activerecord-import/blob/b325ebb644160a09db6e269e414f33561cb21272/lib/activerecord-import/import.rb#L661-L689
      private def values_sql_for_columns_and_attributes(columns, array_of_attributes)
        connection_memo = connection
        type_caster_memo = type_caster if respond_to?(:type_caster)

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
              connection_memo.quote(type_caster_memo.type_cast_for_database(column.name, val))
            end
          end
          "(#{my_values.join(',')})"
        end
      end
    end

    begin
      require "activerecord-import"
      require "activerecord-import/base"
      (class << ActiveRecord::Base; self; end).prepend(ActiverecordImportExt)
    rescue LoadError
    end
  end
end
