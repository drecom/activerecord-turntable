module ActiveRecord::Turntable
  module Base
    extend ActiveSupport::Concern

    included do
      include Compatible
      class_attribute :turntable_connections,
                        :turntable_enabled, :turntable_sequencer_enabled

      self.turntable_connections = {}
      self.turntable_enabled = false
      self.turntable_sequencer_enabled = false
      class << self
        delegate :shards_transaction, :to => :connection
      end
    end

    module ClassMethods
      def turntable(cluster_name, shard_key_name, options = {})
        class_attribute :turntable_shard_key,
                          :turntable_cluster, :turntable_cluster_name

        self.turntable_enabled = true
        self.turntable_cluster_name = cluster_name
        self.turntable_shard_key = shard_key_name
        self.turntable_cluster = Cluster.new(
                                   self,
                                   turntable_config[:clusters][cluster_name],
                                   options
                                 )
        turntable_replace_connection_pool
      end

      def force_transaction_all_shards!(options={}, &block)
        force_connect_all_shards!
        shards = turntable_connections.values
        shards += [ActiveRecord::Base.connection_pool]
        recursive_transaction(shards, options, &block)
      end

      def recursive_transaction(pools, options, &block)
        pool = pools.shift
        if pools.present?
          pool.connection.transaction(options) do
            recursive_transaction(pools, options, &block)
          end
        else
          pool.connection.transaction(options, &block)
        end
      end

      def force_connect_all_shards!
        conf = configurations[Rails.env]
        shards = conf["shards"]
        shards = shards.merge(conf["seq"]) if conf["seq"]
        shards.each do |name, config|
          turntable_connections[name] ||=
            ActiveRecord::ConnectionAdapters::ConnectionPool.new(spec_for(config))
        end
      end

      def turntable_replace_connection_pool
        ch = connection_handler
        cp = turntable_cluster.connection_proxy
        if ActiveRecord::VERSION::STRING >= '3.2.0'
          ch.connection_pools[cp.spec] = PoolProxy.new(cp)
          ch.instance_variable_get(:@class_to_pool)[name] = ch.connection_pools[cp.spec]
        else
          ch.connection_pools[name] = PoolProxy.new(cp)
        end
      end

      def spec_for(config)
        begin
          require "active_record/connection_adapters/#{config['adapter']}_adapter"
        rescue LoadError => e
          raise "Please install the #{config['adapter']} adapter: `gem install activerecord-#{config['adapter']}-adapter` (#{e})"
        end
        adapter_method = "#{config['adapter']}_connection"
        ActiveRecord::Base::ConnectionSpecification.new(config, adapter_method)
      end

      def clear_all_connections!
        turntable_connections.values.each do |pool|
          pool.disconnect!
        end
      end

      def sequencer
        class_attribute :turntable_sequencer
        self.turntable_sequencer_enabled = true
        self.turntable_sequencer = ActiveRecord::Turntable::Sequencer.build(self)
      end

      def turntable_enabled?
        turntable_enabled
      end

      def sequencer_enabled?
        turntable_sequencer_enabled
      end

      def current_sequence
        connection.current_sequence_value(self.sequence_name) if sequencer_enabled?
      end

      def current_last_shard
        turntable_cluster.select_shard(current_sequence) if sequencer_enabled?
      end

      def weighted_random_shard_with(*klasses, &block)
        shards_weight = self.turntable_cluster.weighted_shards
        sum = shards_weight.values.inject(&:+)
        idx = rand(sum)
        shard, weight = shards_weight.find {|k,v|
          (idx -= v) < 0
        }
        self.connection.with_recursive_shards(shard.name, *klasses, &block)
      end
    end

    def shards_transaction(options = {}, &block)
      self.class.shards_transaction(options, &block)
    end

    def turntable_shard
      turntable_cluster.select_shard(self.send(turntable_shard_key))
    end
  end
end
