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
      def values_sql_for_columns_and_attributes_with_turntable(columns, array_of_attributes)
        connection_memo = connection
        array_of_attributes.map do |arr|
          my_values = arr.each_with_index.map do |val,j|
            column = columns[j]

            # be sure to query sequence_name *last*, only if cheaper tests fail, because it's costly
            if val.nil? && column.name == primary_key && !sequence_name.blank?
              if sequencer_enabled?
                connection_memo.next_sequence_value(sequence_name)
              else
                connection_memo.next_value_for_sequence(sequence_name)
              end
            else
              if serialized_attributes.include?(column.name)
                connection_memo.quote(serialized_attributes[column.name].dump(val), column)
              else
                connection_memo.quote(val, column)
              end
            end
          end
          "(#{my_values.join(',')})"
        end
      end
    end

    begin
      require 'activerecord-import'
      require 'activerecord-import/base'
      (class << ActiveRecord::Base; self; end).send(:include, ActiverecordImportExt)
    rescue LoadError
    end
  end
end
