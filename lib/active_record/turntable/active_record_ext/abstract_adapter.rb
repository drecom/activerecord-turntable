module ActiveRecord::Turntable
  module ActiveRecordExt
    module AbstractAdapter
      extend ActiveSupport::Concern

      included do
        protected

        # @note override for logging current shard name
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

      def turntable_shard_name=(name)
        @turntable_shard_name = name.to_s
      end

      def turntable_shard_name
        @turntable_shard_name
      end
    end
  end
end
