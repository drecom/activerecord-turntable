module ActiveRecord::Turntable
  module ActiveRecordExt
    module AbstractAdapter
      def translate_exception_class(e, sql)
        begin
          message = "#{e.class.name}: #{e.message}: #{sql} : #{turntable_shard_name}"
        rescue Encoding::CompatibilityError
          message = "#{e.class.name}: #{e.message.force_encoding sql.encoding}: #{sql} : #{turntable_shard_name}"
        end

        exception = translate_exception(e, message)
        exception.set_backtrace e.backtrace
        exception
      end

      # @note override for append current shard name
      # rubocop:disable Style/HashSyntax, Style/MultilineMethodCallBraceLayout
      def log(sql, name = "SQL", binds = [], statement_name = nil)
        @instrumenter.instrument(
          "sql.active_record",
          :sql                  => sql,
          :name                 => name,
          :connection_id        => object_id,
          :statement_name       => statement_name,
          :binds                => binds,
          :turntable_shard_name => turntable_shard_name) { yield }
      rescue => e
        raise translate_exception_class(e, sql)
      end
      # rubocop:enable Style/HashSyntax, Style/MultilineMethodCallBraceLayout

      protected :translate_exception_class, :log

      def turntable_shard_name=(name)
        @turntable_shard_name = name.to_s
      end

      def turntable_shard_name
        @turntable_shard_name ||= ""
      end
    end
  end
end
