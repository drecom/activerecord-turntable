require 'active_record/log_subscriber'

module ActiveRecord::Turntable
  module ActiveRecordExt
    module LogSubscriber
      extend ActiveSupport::Concern

      included do
        alias_method_chain :sql, :turntable
      end

      protected

      def sql_with_turntable(event)
        self.class.runtime += event.duration
        return unless logger.debug?

        payload = event.payload

        return if ActiveRecord::LogSubscriber::IGNORE_PAYLOAD_NAMES.include?(payload[:name])

        name  = "#{payload[:name]} (#{event.duration.round(1)}ms)"
        shard = '[Shard: %s]' % (event.payload[:turntable_shard_name] ? event.payload[:turntable_shard_name] : nil)
        sql   = payload[:sql].squeeze(' ')
        binds = nil

        unless (payload[:binds] || []).empty?
          binds = "  " + payload[:binds].map { |col,v|
            render_bind(col, v)
          }.inspect
        end

        if odd?
          name = color(name, ActiveRecord::LogSubscriber::CYAN, true)
          shard = color(shard, ActiveRecord::LogSubscriber::CYAN, true)
          sql  = color(sql, nil, true)
        else
          name = color(name, ActiveRecord::LogSubscriber::MAGENTA, true)
          shard = color(shard, ActiveRecord::LogSubscriber::MAGENTA, true)
        end

        debug "  #{name} #{shard} #{sql}#{binds}"
      end
    end
  end
end
