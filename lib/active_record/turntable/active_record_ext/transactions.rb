module ActiveRecord::Turntable
  module ActiveRecordExt
    module Transactions
      # @note Override to start transaction on current shard
      def with_transaction_returning_status
        if self.class.turntable_enabled?
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
              if Util.ar42_or_later?
                clear_transaction_record_state
              else
                @_start_transaction_state[:level] = (@_start_transaction_state[:level] || 0) - 1
              end
              status = nil
            end

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
