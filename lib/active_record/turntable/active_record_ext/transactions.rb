module ActiveRecord::Turntable
  module ActiveRecordExt
    module Transactions
      # @note Override to start transaction on current shard
      def with_transaction_returning_status
        return super unless self.class.turntable_enabled?

        status = nil
        if self.new_record? && self.turntable_shard_key.to_s == self.class.primary_key &&
            self.id.nil? && self.class.connection.prefetch_primary_key?(self.class.table_name)
          self.id = self.class.connection.next_sequence_value(self.class.sequence_name)
        end
        self.class.connection.shards_transaction([self.turntable_shard]) do
          add_to_transaction
          begin
            status = yield
          rescue ActiveRecord::Rollback
            clear_transaction_record_state
            status = nil
          end

          raise ActiveRecord::Rollback unless status
        end
        status
      ensure
        if @transaction_state && @transaction_state.committed?
          clear_transaction_record_state
        end
      end

      def add_to_transaction
        return super unless self.class.turntable_enabled?

        if has_transactional_callbacks?
          self.turntable_shard.connection.add_transaction_record(self)
        else
          sync_with_transaction_state
          set_transaction_state(self.turntable_shard.connection.transaction_state)
        end
        remember_transaction_record_state
      end
    end
  end
end
