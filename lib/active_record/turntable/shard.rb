module ActiveRecord::Turntable
  class Shard
    DEFAULT_CONFIG = {
      "connection" => (defined?(Rails) ? Rails.env : "development")
    }.with_indifferent_access

    def initialize(shard_spec)
      @config = DEFAULT_CONFIG.merge(shard_spec)
      @name = @config["connection"]
    end

    def connection_pool
      @connection_pool ||= retrieve_connection_pool
    end

    def connection
      connection = connection_pool.connection
      connection.turntable_shard_name = name
      connection
    end

    def name
      @name
    end

    private

    def retrieve_connection_pool
      ActiveRecord::Base.turntable_connections[name] ||=
        begin
          config = ActiveRecord::Base.configurations[Rails.env]["shards"][name]
          raise ArgumentError, "Unknown database config: #{name}, have #{ActiveRecord::Base.configurations.inspect}" unless config
          ActiveRecord::ConnectionAdapters::ConnectionPool.new(spec_for(config))
        end
    end

    def spec_for(config)
      begin
        require "active_record/connection_adapters/#{config['adapter']}_adapter"
      rescue LoadError => e
        raise "Please install the #{config['adapter']} adapter: `gem install activerecord-#{config['adapter']}-adapter` (#{e})"
      end
      adapter_method = "#{config['adapter']}_connection"

      if ActiveRecord::VERSION::STRING > "4.0"
        ActiveRecord::ConnectionAdapters::ConnectionSpecification.new(config, adapter_method)
      else
        ActiveRecord::Base::ConnectionSpecification.new(config, adapter_method)
      end
    end
  end
end
