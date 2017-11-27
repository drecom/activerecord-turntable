module ActiveRecord::Turntable
  class Shard
    module Connections; end
    def self.connection_classes
      Connections.constants.map { |name| Connections.const_get(name) }
    end

    attr_accessor :name

    def initialize(name = defined?(Rails) ? Rails.env : "development")
      @name = name
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

      def create_connection_class
        klass = connection_class_instance
        klass.remove_connection
        klass.establish_connection ActiveRecord::Base.connection_pool.spec.config[:shards][name].with_indifferent_access
        klass
      end

      def connection_class_instance
        if Connections.const_defined?(name.classify)
          klass = Connections.const_get(name.classify)
        else
          klass = Class.new(ActiveRecord::Base)
          Connections.const_set(name.classify, klass)
          klass.abstract_class = true
        end
        klass
      end
  end
end
