module ActiveRecord::Turntable
  class SeqShard < Shard
    private
    def retrieve_connection_pool
      ActiveRecord::Base.turntable_connections[name] ||=
        begin
          config = ActiveRecord::Base.configurations[Rails.env]["seq"][name]
          raise ArgumentError, "Unknown database config: #{name}, have #{ActiveRecord::Base.configurations.inspect}" unless config
          ActiveRecord::ConnectionAdapters::ConnectionPool.new(spec_for(config))
        end
    end
  end
end

