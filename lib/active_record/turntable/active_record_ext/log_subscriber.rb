require "active_record/log_subscriber"

module ActiveRecord::Turntable
  module ActiveRecordExt
    module LogSubscriber
      # @note prepend to add shard name logging
      def sql(event)
        payload = event.payload

        if self.class::IGNORE_PAYLOAD_NAMES.include?(payload[:name])
          self.class.runtime += event.duration
          return
        end

        if payload[:turntable_shard_name]
          payload[:name] = "#{payload[:name]} [Shard: #{payload[:turntable_shard_name]}]"
        end
        super
      end
    end
  end
end
