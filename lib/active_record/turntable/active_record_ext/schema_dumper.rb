# -*- coding: utf-8 -*-
module ActiveRecord::Turntable
  module ActiveRecordExt
    module SchemaDumper

      private

        # @note Override to dump database sequencer method
        def table(table, stream)
          columns = @connection.columns(table)
          begin
            tbl = StringIO.new

            # first dump primary key column
            if @connection.respond_to?(:primary_keys)
              pk = @connection.primary_keys(table)
              pk = pk.first unless pk.size > 1
            else
              pk = @connection.primary_key(table)
            end

            if table =~ /\A(.*)_id_seq\z/
              tbl.print "  create_sequence_for #{remove_prefix_and_suffix(Regexp.last_match(1)).inspect}"
            else
              tbl.print "  create_table #{remove_prefix_and_suffix(table).inspect}"
            end

            case pk
            when String
              tbl.print ", primary_key: #{pk.inspect}" unless pk == 'id'
              pkcol = columns.detect { |c| c.name == pk }
              pkcolspec = @connection.column_spec_for_primary_key(pkcol)
              if pkcolspec.present?
                pkcolspec.each do |key, value|
                  tbl.print ", #{key}: #{value}"
                end
              end
            when Array
              tbl.print ", primary_key: #{pk.inspect}"
            else
              tbl.print ", id: false"
            end
            tbl.print ", force: :cascade"

            table_options = @connection.table_options(table)
            tbl.print ", options: #{table_options.inspect}" unless table_options.blank?

            if comment = @connection.table_comment(table).presence
              tbl.print ", comment: #{comment.inspect}"
            end

            tbl.puts " do |t|"

            # then dump all non-primary key columns
            column_specs = columns.map do |column|
              raise StandardError, "Unknown type '#{column.sql_type}' for column '#{column.name}'" unless @connection.valid_type?(column.type)
              next if column.name == pk
              @connection.column_spec(column)
            end.compact

            # find all migration keys used in this table
            keys = @connection.migration_keys

            # figure out the lengths for each column based on above keys
            lengths = keys.map { |key|
              column_specs.map { |spec|
                spec[key] ? spec[key].length + 2 : 0
              }.max
            }

            # the string we're going to sprintf our values against, with standardized column widths
            format_string = lengths.map{ |len| "%-#{len}s" }

            # find the max length for the 'type' column, which is special
            type_length = column_specs.map{ |column| column[:type].length }.max

            # add column type definition to our format string
            format_string.unshift "    t.%-#{type_length}s "

            format_string *= ''

            column_specs.each do |colspec|
              values = keys.zip(lengths).map{ |key, len| colspec.key?(key) ? colspec[key] + ", " : " " * len }
              values.unshift colspec[:type]
              tbl.print((format_string % values).gsub(/,\s*$/, ''))
              tbl.puts
            end

            indexes_in_create(table, tbl)

            tbl.puts "  end"
            tbl.puts

            tbl.rewind
            stream.print tbl.read
          rescue => e
            stream.puts "# Could not dump table #{table.inspect} because of following #{e.class}"
            stream.puts "#   #{e.message}"
            stream.puts
          end

          stream
        end
    end
  end
end
