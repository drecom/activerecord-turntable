module ActiveRecord::Turntable
  module ActiveRecordExt
    # activerecord-import extension
    module ActiverecordImportExt
      # @note override for sequencer injection
      # @see https://github.com/zdennis/activerecord-import/blob/85586d052822b8d498ced6c900251997edbeee04/lib/activerecord-import/import.rb#L848-L883
      private def values_sql_for_columns_and_attributes(columns, array_of_attributes)
        connection_memo = connection

        array_of_attributes.map do |arr|
          my_values = arr.each_with_index.map do |val, j|
            column = columns[j]

            # be sure to query sequence_name *last*, only if cheaper tests fail, because it's costly
            if val.nil? && column.name == primary_key && !sequence_name.blank?
              if sequencer_enabled?
                self.next_sequence_value
              else
                connection_memo.next_value_for_sequence(sequence_name)
              end
            elsif val.respond_to?(:to_sql)
              "(#{val.to_sql})"
            elsif column
              type = type_for_attribute(column.name)
              val = type.type == :boolean ? type.cast(val) : type.serialize(val)
              connection_memo.quote(val)
            end
          end
          "(#{my_values.join(',')})"
        end
      end
    end

    begin
      require "activerecord-import"
      require "activerecord-import/base"
      require "activerecord-import/active_record/adapters/mysql2_adapter"
      ActiveRecord::Turntable::ConnectionProxy.include(ActiveRecord::Import::Mysql2Adapter)
      (class << ActiveRecord::Base; self; end).prepend(ActiverecordImportExt)
    rescue LoadError # rubocop:disable Lint/HandleExceptions
    end
  end
end
