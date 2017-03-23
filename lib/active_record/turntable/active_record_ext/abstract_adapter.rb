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
      if ActiveRecord::Turntable::Util.ar51_or_later?
        def log(sql, name = "SQL", binds = [], type_casted_binds = [], statement_name = nil)
          @instrumenter.instrument(
            "sql.active_record",
            sql:                  sql,
            name:                 name,
            binds:                binds,
            type_casted_binds:    type_casted_binds,
            statement_name:       statement_name,
            connection_id:        object_id,
            turntable_shard_name: turntable_shard_name) do
              @lock.synchronize do
                yield
              end
            end
        rescue => e
          raise translate_exception_class(e, sql)
        end
      elsif ActiveRecord::Turntable::Util.ar_version_equals_or_later?("5.0.3")
        def log(sql, name = "SQL", binds = [], type_casted_binds = [], statement_name = nil) # :doc:
          @instrumenter.instrument(
            "sql.active_record",
            sql:                  sql,
            name:                 name,
            binds:                binds,
            type_casted_binds:    type_casted_binds,
            statement_name:       statement_name,
            connection_id:        object_id,
            turntable_shard_name: turntable_shard_name) { yield }
        rescue => e
          raise translate_exception_class(e, sql)
        end
      else
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
      end
      # rubocop:enable Style/HashSyntax, Style/MultilineMethodCallBraceLayout

      protected :translate_exception_class, :log

      def turntable_shard_name=(name)
        @turntable_shard_name = name.to_s
      end

      def turntable_shard_name
        instance_variable_defined?(:@turntable_shard_name) ? @turntable_shard_name : nil
      end
    end
  end
end
