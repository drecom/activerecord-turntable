module ActiveRecord::Turntable
  class Shard
    module Connections; end
    def self.connection_classes
      Connections.constants.map { |name| Connections.const_get(name) }
    end

    DEFAULT_CONFIG = {
      "connection" => (defined?(Rails) ? Rails.env : "development"),
    }.with_indifferent_access

    attr_reader :name

    def initialize(shard_spec)
      @config = DEFAULT_CONFIG.merge(shard_spec)
      @name = @config[:connection]
      ActiveRecord::Base.turntable_connections[name] = connection_pool
    end

    def connection_pool
      connection_klass.connection_pool
    end

    def connection
      connection_pool.connection.tap do |conn|
        conn.turntable_shard_name ||= name
      end
    end

    private

      def connection_klass
        @connection_klass ||= create_connection_class
      end

      def get_or_set_connection_class
        if Connections.const_defined?(name.classify)
          klass = Connections.const_get(name.classify)
        else
          klass = Class.new(ActiveRecord::Base)
          Connections.const_set(name.classify, klass)
          klass.abstract_class = true
        end
        klass
      end

      def create_connection_class
        klass = get_or_set_connection_class
        klass.remove_connection
        klass.establish_connection ActiveRecord::Base.connection_pool.spec.config[:shards][name].with_indifferent_access
        klass
      end
  end
end
