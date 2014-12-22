require 'active_support/core_ext/hash/indifferent_access'

module ActiveRecord::Turntable
  class Cluster

    DEFAULT_CONFIG = {
      "shards" => [],
      "algorithm" => "range",
    }.with_indifferent_access

    def initialize(klass, cluster_spec, options = {})
      @klass = klass
      @config = DEFAULT_CONFIG.merge(cluster_spec)
      @options = options.with_indifferent_access
      @shards = {}.with_indifferent_access

      # setup master shard
      @master_shard = MasterShard.new(klass)

      # setup sequencer
      if (seq = (@options[:seq] || @config[:seq])) && seq[:type] == :mysql
        @seq_shard = SeqShard.new(seq)
      end

      # setup shards
      @config[:shards].each do |spec|
        @shards[spec["connection"]] ||= Shard.new(spec)
      end

      # setup algorithm
      alg_name = "ActiveRecord::Turntable::Algorithm::#{@config["algorithm"].camelize}Algorithm"
      @algorithm = alg_name.constantize.new(@config)

      # setup proxy
      @connection_proxy = ConnectionProxy.new(self, cluster_spec)
    end

    def klass
      @klass
    end

    def master
      @master_shard
    end

    def seq
      @seq_shard || @master_shard
    end

    def shards
      @shards
    end

    def connection_proxy
      @connection_proxy
    end

    def shard_for(key)
      @shards[@algorithm.calculate(key)]
    rescue
      raise ActiveRecord::Turntable::CannotSpecifyShardError,
      "[#{klass}] cannot select_shard for key:#{key}"
    end

    def select_shard(key)
      ActiveSupport::Deprecation.warn "Cluster#select_shard is deprecated, use shard_for() instead.", caller
      shard_for(key)
    end

    def shards_transaction(shards = [], options = {}, in_recursion = false, &block)
      unless in_recursion
        shards = Array.wrap(shards).dup
        if shards.blank?
          shards = @shards.values.dup
        end
      end
      shard_or_object = shards.shift
      shard = to_shard(shard_or_object)
      if shards.present?
        shard.connection.transaction(options) do
          shards_transaction(shards, options, true, &block)
        end
      else
        shard.connection.transaction(options) do
          block.call
        end
      end
    end

    def to_shard(shard_or_object)
      case shard_or_object
      when ActiveRecord::Turntable::Shard
        shard_or_object
      when ActiveRecord::Base
        shard_or_object.turntable_shard
      when Numeric, String
        shard_for(shard_or_object)
      when Symbol
        shards[shard_or_object]
      else
        raise ActiveRecord::Turntable::TurntableError,
                "transaction cannot call to object: #{shard_or_object}"
      end
    end

    def weighted_shards(key = nil)
      key ||= @klass.current_sequence
      Hash[@algorithm.calculate_used_shards_with_weight(key).map do |k,v|
        [@shards[k], v]
      end]
    end
  end
end
