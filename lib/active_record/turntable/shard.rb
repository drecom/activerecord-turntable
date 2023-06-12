module ActiveRecord::Turntable
  class Shard
    module Connections; end
    def self.connection_classes
      Connections.constants.map { |name| Connections.const_get(name) }
    end

    attr_accessor :cluster, :name, :slaves

    def initialize(cluster, name = defined?(Rails) ? Rails.env : "development", slaves = [])
      @cluster = cluster
      @name = name
      @slaves = slaves.map { |s| SlaveShard.new(cluster, s) }
    end

    def connection_pool
      connection_klass.connection_pool
    end

    def connection
      if use_slave?
        current_slave_shard.connection
      else
        connection_pool.connection.tap do |conn|
          conn.turntable_shard_name ||= name
        end
      end
    end

    def support_slave?
      @slaves.size > 0
    end

    def use_slave?
      support_slave? && cluster.slave_enabled?
    end

    def current_slave_shard
      SlaveRegistry.slave_for(self) || SlaveRegistry.set_slave_for(self, any_slave)
    end

    private

      def connection_klass
        @connection_klass ||= connection_class_instance
      end

      def connection_class_instance
        if Connections.const_defined?(name.classify)
          klass = Connections.const_get(name.classify)
        else
          klass = Class.new(ActiveRecord::Base)
          Connections.const_set(name.classify, klass)
          klass.abstract_class = true
          if Util.ar61_or_later?
            klass.establish_connection ActiveRecord::Base.connection_pool.db_config.configuration_hash[:shards][name].with_indifferent_access
          else
            klass.establish_connection ActiveRecord::Base.connection_pool.spec.config[:shards][name].with_indifferent_access
          end
        end
        klass
      end

      def set_current_slave_shard(slave)
        SlaveRegistry.set_slave_for(self, slave)
      end

      def any_slave
        slaves.sample
      end
  end
end
