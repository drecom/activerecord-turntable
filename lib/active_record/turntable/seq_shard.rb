module ActiveRecord::Turntable
  class SeqShard < Shard
    private

    def create_connection_class
      klass = get_or_set_connection_class
      klass.remove_connection
      klass.establish_connection ActiveRecord::Base.connection_pool.spec.config[:seq][name].with_indifferent_access
      klass
    end
 
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
