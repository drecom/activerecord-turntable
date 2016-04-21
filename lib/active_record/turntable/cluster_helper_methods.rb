module ActiveRecord::Turntable
  module ClusterHelperMethods
    extend ActiveSupport::Concern

    included do
      ActiveSupport.on_load(:turntable_config_loaded) do
        turntable_clusters.each do |name, _cluster|
          turntable_define_cluster_methods(name)
        end
      end
    end

    module ClassMethods
      def force_transaction_all_shards!(options = {}, &block)
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

      def weighted_random_shard_with(*klasses, &block)
        shards_weight = self.turntable_cluster.weighted_shards(self.current_sequence)
        sum = shards_weight.values.inject(&:+)
        idx = rand(sum)
        shard, weight = shards_weight.find {|_k, v|
          (idx -= v) < 0
        }
        self.connection.with_recursive_shards(shard.name, *klasses, &block)
      end

      def all_cluster_transaction(options = {})
        clusters = turntable_clusters.values
        recursive_cluster_transaction(clusters) { yield }
      end

      def recursive_cluster_transaction(clusters, options = {}, &block)
        current_cluster = clusters.shift
        current_cluster.shards_transaction do
          if clusters.present?
            recursive_cluster_transaction(clusters, options, &block)
          else
            yield
          end
        end
      end

      def turntable_define_cluster_methods(cluster_name)
        turntable_define_cluster_class_methods(cluster_name)
      end

      def turntable_define_cluster_class_methods(cluster_name)
        (class << ActiveRecord::Base; self; end).class_eval <<-EOD
          unless respond_to?(:#{cluster_name}_transaction)
            def #{cluster_name}_transaction(shards = [], options = {})
              cluster = turntable_clusters[#{cluster_name.inspect}]
              cluster.shards_transaction(shards, options) { yield }
            end
          end
        EOD
      end
    end
  end
end
