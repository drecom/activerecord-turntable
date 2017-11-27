require "active_support/lazy_load_hooks"

module ActiveRecord::Turntable
  module Base
    extend ActiveSupport::Concern

    included do
      class_attribute :turntable_connections, :turntable_clusters, :turntable_sequencers,
                      :turntable_enabled, :turntable_sequencer_enabled, :turntable_configuration

      self.turntable_connections = {}
      self.turntable_clusters = {}.with_indifferent_access
      self.turntable_sequencers = {}.with_indifferent_access
      self.turntable_enabled = false
      self.turntable_sequencer_enabled = false

      class << self
        delegate :shards_transaction, :with_all, to: :connection

        def reset_turntable_configuration(configuration, reset = true)
          old = self.turntable_configuration
          self.turntable_configuration = configuration

          old.release! if old

          if reset
            # TODO: replace exitsting connection_pool when configurations reloaded
            self.turntable_clusters = turntable_configuration.clusters
            self.turntable_sequencers = turntable_configuration.sequencers
            ActiveSupport.run_load_hooks(:turntable_configuration_loaded, ActiveRecord::Base)
          end
        end
      end

      include ClusterHelperMethods
    end

    module ClassMethods
      # @param [Symbol] cluster_name cluster name for this class
      # @param [Symbol] shard_key_name shard key attribute name
      # @param [Hash] options
      def turntable(cluster_name, shard_key_name, options = {})
        class_attribute :turntable_shard_key, :turntable_cluster_name

        self.turntable_enabled = true
        self.turntable_cluster_name = cluster_name
        self.turntable_shard_key = shard_key_name
        turntable_replace_connection_pool
      end

      def turntable_cluster
        turntable_clusters[turntable_cluster_name]
      end

      def turntable_replace_connection_pool
        ch = connection_handler
        cp = ConnectionProxy.new(self, turntable_cluster)
        pp = PoolProxy.new(cp)

        self.connection_specification_name = "turntable_pool_proxy::#{name}"
        ch.send(:owner_to_pool)[connection_specification_name] = pp
      end

      def clear_all_connections!
        turntable_connections.values.each(&:disconnect!)
      end

      def sequencer(sequencer_name, *args)
        class_attribute :turntable_sequencer_name
        class << self
          prepend ActiveRecordExt::Sequencer
        end

        self.turntable_sequencer_enabled = true
        self.turntable_sequencer_name = sequencer_name
      end

      def turntable_sequencer
        turntable_sequencers[turntable_sequencer_name]
      end

      def turntable_enabled?
        turntable_enabled
      end

      def sequencer_enabled?
        turntable_sequencer_enabled
      end

      def current_last_shard
        turntable_cluster.select_shard(current_sequence_value) if sequencer_enabled?
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

      def with_slave
        connection.with_slave { yield }
      end

      def with_master
        connection.with_master { yield }
      end
    end

    delegate :shards_transaction, :turntable_cluster, to: :class

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
