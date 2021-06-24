module ActiveRecord::Turntable
  module ActiveRecordExt
    module AbstractAdapter
      extend Compatibility

      def self.prepended(klass)
        klass.prepend(self.compatible_module)
        klass.class_eval { protected :log }
      end

      def translate_exception_class(e, sql, binds)
        begin
          message = "#{e.class.name}: #{e.message}: #{sql} : #{turntable_shard_name}"
        rescue Encoding::CompatibilityError
          message = "#{e.class.name}: #{e.message.force_encoding sql.encoding}: #{sql} : #{turntable_shard_name}"
        end

        exception =
          if Util.ar60_or_later?
            translate_exception(e, message: message, sql: sql, binds: binds)
          else
            translate_exception(e, message)
          end
        exception.set_backtrace e.backtrace
        exception
      end
      protected :translate_exception_class

      # @note override for append current shard name
      # rubocop:disable Style/HashSyntax, Style/MultilineMethodCallBraceLayout
      module V6_0
        def log(sql, name = "SQL", binds = [], type_casted_binds = [], statement_name = nil)
          @instrumenter.instrument(
            "sql.active_record",
            sql:                  sql,
            name:                 name,
            binds:                binds,
            type_casted_binds:    type_casted_binds,
            statement_name:       statement_name,
            connection:           self,
            turntable_shard_name: turntable_shard_name) do
            begin
              @lock.synchronize do
                yield
              end
            rescue => e
              raise translate_exception_class(e, sql, binds)
            end
          end
        end
      end

      module V5_2
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
            begin
              @lock.synchronize do
                yield
              end
            rescue => e
              raise translate_exception_class(e, sql, binds)
            end
          end
        end
      end

      module V5_1
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
          raise translate_exception_class(e, sql, binds)
        end
      end

      module V5_0_3
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
          raise translate_exception_class(e, sql, binds)
        end
      end

      module V5_0
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
          raise translate_exception_class(e, sql, binds)
        end
      end
      # rubocop:enable Style/HashSyntax, Style/MultilineMethodCallBraceLayout


      def turntable_shard_name=(name)
        @turntable_shard_name = name.to_s
      end

      def turntable_shard_name
        instance_variable_defined?(:@turntable_shard_name) ? @turntable_shard_name : nil
      end
    end
  end
end
