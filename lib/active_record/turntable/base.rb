module ActiveRecord::Turntable
  module Base
    extend ActiveSupport::Concern

    included do
      class_attribute :turntable_connections,
                        :turntable_enabled, :turntable_sequencer_enabled

      self.turntable_connections = {}
      self.turntable_enabled = false
      self.turntable_sequencer_enabled = false
      class << self
        delegate :shards_transaction, :with_all, :to => :connection
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
        shards = {}
        shards = shards.merge(conf["shards"]) if conf["shards"]
        shards = shards.merge(conf["seq"]) if conf["seq"]
        shards.each do |name, config|
          turntable_connections[name] ||=
            ActiveRecord::ConnectionAdapters::ConnectionPool.new(spec_for(config))
        end
      end

      def turntable_replace_connection_pool
        ch = connection_handler
        cp = turntable_cluster.connection_proxy
        pp = PoolProxy.new(cp)
        ch.class_to_pool.clear if defined?(ch.class_to_pool)
        ch.send(:owner_to_pool)[name].try(:disconnect!)
        ch.send(:class_to_pool)[name] = ch.send(:owner_to_pool)[name] = pp
      end

      def spec_for(config)
        begin
          require "active_record/connection_adapters/#{config['adapter']}_adapter"
        rescue LoadError => e
          raise "Please install the #{config['adapter']} adapter: `gem install activerecord-#{config['adapter']}-adapter` (#{e})"
        end
        adapter_method = "#{config['adapter']}_connection"
        ActiveRecord::ConnectionAdapters::ConnectionSpecification.new(config, adapter_method)
      end

      def clear_all_connections!
        turntable_connections.values.each do |pool|
          pool.disconnect!
        end
      end

      def sequencer(sequence_name, *args)
        class_attribute :turntable_sequencer

        self.turntable_sequencer_enabled = true
        self.turntable_sequencer = ActiveRecord::Turntable::Sequencer.build(self, sequence_name, *args)
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

      def with_shard(any_shard)
        shard = case any_shard
                when Numeric
                  turntable_cluster.shard_for(any_shard)
                when ActiveRecord::Base
                  turntable_cluster.shard_for(any_shard.send(any_shard.turntable_shard_key))
                else
                  shard_or_key
                end
        connection.with_shard(shard) { yield }
      end
    end

    def shards_transaction(options = {}, &block)
      self.class.shards_transaction(options, &block)
    end

    def turntable_shard
      turntable_cluster.shard_for(self.send(turntable_shard_key))
    end

    def with_shard(shard)
      self.class.connection.with_shard(shard) { yield }
    end
  end
end
