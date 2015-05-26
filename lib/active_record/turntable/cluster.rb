require 'active_support/core_ext/hash/indifferent_access'

module ActiveRecord::Turntable
  class Cluster

    DEFAULT_CONFIG = {
      "shards" => [],
      "algorithm" => "range",
    }.with_indifferent_access

    def initialize(cluster_spec, options = {})
      @config = DEFAULT_CONFIG.merge(cluster_spec)
      @options = options.with_indifferent_access
      @shards = {}.with_indifferent_access

      # setup sequencer
      seq = (@options[:seq] || @config[:seq])
      if seq 
        if seq.values.size > 0 && seq.values.first["seq_type"] == "mysql"
          @seq_shard = SeqShard.new(seq.values.first)
        end
      end

      # setup shards
      @config[:shards].each do |spec|
        @shards[spec["connection"]] ||= Shard.new(spec)
      end

      # setup algorithm
      alg_name = "ActiveRecord::Turntable::Algorithm::#{@config["algorithm"].camelize}Algorithm"
      @algorithm = alg_name.constantize.new(@config)
    end

    def seq
      @seq_shard
    end

    def shards
      @shards
    end

    def shard_for(key)
      @shards[@algorithm.calculate(key)]
    rescue
      raise ActiveRecord::Turntable::CannotSpecifyShardError,
        "cannot select_shard for key:#{key}"
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
      shard = to_shard(shards.shift)
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
      Hash[@algorithm.calculate_used_shards_with_weight(key).map do |k,v|
        [@shards[k], v]
      end]
    end
  end
end
