require "active_support/lazy_load_hooks"

module ActiveRecord::Turntable
  module Base
    extend ActiveSupport::Concern

    included do
      class_attribute :turntable_connections, :turntable_clusters,
                      :turntable_enabled, :turntable_sequencer_enabled

      self.turntable_connections = {}
      self.turntable_clusters = {}.with_indifferent_access
      self.turntable_enabled = false
      self.turntable_sequencer_enabled = false
      class << self
        delegate :shards_transaction, :with_all, to: :connection
      end

      ActiveSupport.on_load(:turntable_config_loaded) do
        self.initialize_clusters!
      end
      include ClusterHelperMethods
    end

    module ClassMethods
      # @param [Symbol] cluster_name cluster name for this class
      # @param [Symbol] shard_key_name shard key attribute name
      # @param [Hash] options
      def turntable(cluster_name, shard_key_name, options = {})
        class_attribute :turntable_shard_key,
                        :turntable_cluster, :turntable_cluster_name

        self.turntable_enabled = true
        self.turntable_cluster_name = cluster_name
        self.turntable_shard_key = shard_key_name
        self.turntable_cluster =
          self.turntable_clusters[cluster_name] ||= Cluster.new(
            turntable_config[:clusters][cluster_name],
            options
          )
        turntable_replace_connection_pool
      end

      def turntable_replace_connection_pool
        ch = connection_handler
        cp = ConnectionProxy.new(self, turntable_cluster)
        pp = PoolProxy.new(cp)
        ch.class_to_pool.clear if defined?(ch.class_to_pool)
        ch.send(:class_to_pool)[name] = ch.send(:owner_to_pool)[name] = pp
      end

      def initialize_clusters!
        turntable_config[:clusters].each do |name, spec|
          self.turntable_clusters[name] ||= Cluster.new(spec, {})
        end
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
        turntable_connections.values.each(&:disconnect!)
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

    # @return [ActiveRecord::Turntable::Shard] current shard for self
    def turntable_shard
      turntable_cluster.shard_for(self.send(turntable_shard_key))
    end

    # @see ActiveRecord::Turntable::ConnectionProxy#with_shard
    def with_shard(shard)
      self.class.connection.with_shard(shard) { yield }
    end
  end
end
