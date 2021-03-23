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
            if Util.ar60_or_later?
              self.table_name = table
            end

            tbl = StringIO.new

            tbl.print "  create_sequence_for #{remove_prefix_and_suffix(matchdata[1]).inspect}"
            tbl.print ", force: :cascade"

            table_options = @connection.table_options(table)
            if table_options.present?
              if respond_to?(:format_options, true)
                tbl.print ", #{format_options(table_options)}"
              else
                tbl.print ", options: #{table_options.inspect}"
              end
            end

            if Util.ar_version_earlier_than?("5.0.1") && comment = @connection.table_comment(table).presence
              tbl.print ", comment: #{comment.inspect}"
            end
            tbl.puts

            tbl.rewind
            stream.print tbl.read
          rescue => e
            stream.puts "# Could not dump table #{table.inspect} because of following #{e.class}"
            stream.puts "#   #{e.message}"
            stream.puts
          ensure
            if Util.ar60_or_later?
              self.table_name = nil
            end
          end

          stream
        end
    end
  end
end
