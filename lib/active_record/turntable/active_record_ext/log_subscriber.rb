require "active_record/log_subscriber"

module ActiveRecord::Turntable
  module ActiveRecordExt
    module LogSubscriber
      # @note prepend to add shard name logging
      def sql(event)
        payload = event.payload
        if payload[:turntable_shard_name]
          payload[:name] = "#{payload[:name]} [Shard: #{payload[:turntable_shard_name]}]"
        end
        super
      end
    end
  end
end
