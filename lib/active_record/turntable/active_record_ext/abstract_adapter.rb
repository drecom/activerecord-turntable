module ActiveRecord::Turntable
  module ActiveRecordExt
    module AbstractAdapter
      extend ActiveSupport::Concern

      included do
        protected

        if ActiveRecord::VERSION::STRING < '3.1'
          def log(sql, name)
            name ||= "SQL"
            @instrumenter.instrument("sql.active_record",
                                     :sql => sql, :name => name, :connection_id => object_id,
                                     :turntable_shard_name => turntable_shard_name) do
              yield
            end
          rescue Exception => e
            message = "#{e.class.name}: #{e.message}: #{sql} : #{turntable_shard_name}"
            @logger.debug message if @logger
            raise translate_exception(e, message)
          end
        else
          def log(sql, name = "SQL", binds = [])
            @instrumenter.instrument(
                                     "sql.active_record",
                                     :sql           => sql,
                                     :name          => name,
                                     :connection_id => object_id,
                                     :binds         => binds,
                                     :turntable_shard_name => turntable_shard_name) { yield }
          rescue Exception => e
            message = "#{e.class.name}: #{e.message}: #{sql} : #{turntable_shard_name}"
            @logger.debug message if @logger
            exception = translate_exception(e, message)
            exception.set_backtrace e.backtrace
            raise exception
          end
        end
      end

      def turntable_shard_name=(name)
        @turntable_shard_name = name.to_s
      end

      def turntable_shard_name
        @turntable_shard_name
      end
    end
  end
end
