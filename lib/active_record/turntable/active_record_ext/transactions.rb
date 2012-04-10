module ActiveRecord::Turntable
  module ActiveRecordExt
    module Transactions
      def with_transaction_returning_status
        if self.class.turntable_enabled?
          status = nil
          if self.new_record? and self.turntable_shard_key.to_s == self.class.primary_key and
              self.id.nil? and connection.prefetch_primary_key?(self.class.table_name)
            self.id = connection.next_sequence_value(self.class.sequence_name)
          end
          self.class.connection.shards_transaction([self.turntable_shard]) do
            add_to_transaction
            status = yield
            raise ActiveRecord::Rollback unless status
          end
          status
        else
          super
        end
      end

      def add_to_transaction
        if self.class.turntable_enabled?
          if self.turntable_shard.connection.add_transaction_record(self)
            remember_transaction_record_state
          end
        else
          super
        end
      end
    end
  end
end
