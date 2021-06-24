require "active_record/log_subscriber"

module ActiveRecord::Turntable
  module ActiveRecordExt
    module LogSubscriber
      # @note prepend to add shard name logging
      def sql(event)
        self.class.runtime += event.duration
        return unless logger.debug?

        payload = event.payload

        return if ActiveRecord::LogSubscriber::IGNORE_PAYLOAD_NAMES.include?(payload[:name])

        name  = "#{payload[:name]} (#{event.duration.round(1)}ms)"
        name  = "#{name} [Shard: #{payload[:turntable_shard_name]}]" if payload[:turntable_shard_name]
        name  = "CACHE #{name}" if payload[:cached]
        sql   = payload[:sql]
        binds = nil

        unless (payload[:binds] || []).empty?
          if Util.ar_version_equals_or_later?("5.0.3")
            casted_params = if Util.ar_version_satisfy?(">= 5.1.5") || Util.ar_version_satisfy?([">= 5.0.7", "< 5.1"])
                              type_casted_binds(payload[:type_casted_binds])
                            else
                              type_casted_binds(payload[:binds], payload[:type_casted_binds])
                            end
            binds = "  " + payload[:binds].zip(casted_params).map { |attr, value|
              render_bind(attr, value)
            }.inspect
          else
            binds = "  " + payload[:binds].map { |attr| render_bind(attr) }.inspect
          end
        end

        name = colorize_payload_name(name, payload[:name])
        sql  = color(sql, sql_color(sql), true) if Util.ar60_or_later? && colorize_logging

        debug "  #{name}  #{sql}#{binds}"
      end
    end
  end
end
