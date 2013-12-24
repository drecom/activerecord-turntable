module ActiveRecord::Turntable
  module ActiveRecordExt
    module LogSubscriber
      extend ActiveSupport::Concern

      included do
        def sql(event)
          self.class.runtime += event.duration
          return unless logger.debug?

          payload = event.payload

          return if 'SCHEMA' == payload[:name]

          name    = '%s (%.1fms)' % [payload[:name], event.duration]
          shard = '[Shard: %s]' % (event.payload[:turntable_shard_name] ? event.payload[:turntable_shard_name] : nil)
          sql     = payload[:sql].squeeze(' ')
          binds   = nil

          unless (payload[:binds] || []).empty?
            binds = "  " + payload[:binds].map { |col,v|
              [col.name, v]
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
end
