# -*- coding: utf-8 -*-
module ActiveRecord::Turntable
  module ActiveRecordExt
    module SchemaDumper
      SEQUENCE_TABLE_REGEXP = /\A(.*)_id_seq\z/

      private

        # @note Override to dump database sequencer method
        def table(table, stream)
          unless matchdata = table.match(SEQUENCE_TABLE_REGEXP)
            return super
          end

          begin
            tbl = StringIO.new

            tbl.print "  create_sequence_for #{remove_prefix_and_suffix(matchdata[1]).inspect}"
            tbl.print ", force: :cascade"

            table_options = @connection.table_options(table)
            if table_options.present?
              options = respond_to?(:format_options) ? format_options(table_options) : table_options.inspect
              tbl.print ", options: #{options}"
            end

            if comment = @connection.table_comment(table).presence
              tbl.print ", comment: #{comment.inspect}"
            end
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
