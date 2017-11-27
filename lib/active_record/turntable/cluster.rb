require "active_support/core_ext/hash/indifferent_access"
require "concurrent/atomic/thread_local_var"

module ActiveRecord::Turntable
  class Cluster
    DEFAULT_CONFIG = {
      "shards" => [],
      "algorithm" => "range",
    }.with_indifferent_access

    attr_accessor :algorithm, :shard_registry, :sequencer_registry

    def initialize
      @slave_enabled = Concurrent::ThreadLocalVar.new(false)
    end

    def self.build(sequencer_registry)
      self.new.tap do |instance|
        instance.shard_registry = ShardRegistry.new(instance)
        instance.sequencer_registry = sequencer_registry
        yield instance
      end
    end

    delegate :shards, :shard_maps, :release!, to: :shard_registry

    def shard_for(key)
      algorithm.choose(shard_maps, key)
    rescue
      raise ActiveRecord::Turntable::CannotSpecifyShardError,
            "cannot select shard for key:#{key.inspect}"
    end

    def select_shard(key)
      ActiveSupport::Deprecation.warn "Cluster#select_shard is deprecated, use shard_for() instead.", caller
      shard_for(key)
    end

    def shards_transaction(shards = [], options = {}, in_recursion = false, &block)
      unless in_recursion
        shards = Array.wrap(shards).dup
        if shards.blank?
          shards = self.shards.dup
        end
      end
      shard = to_shard(shards.shift)
      if shards.present?
        shard.connection.transaction(options) do
          shards_transaction(shards, options, true, &block)
        end
      else
        shard.connection.transaction(options) do
          yield
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

    def slave_enabled?
      @slave_enabled.value
    end

    def set_slave_enabled(enabled)
      @slave_enabled.value = enabled
    end

    def sequencers
      sequencer_registry.all
    end

    def sequencer(name)
      sequencers[name]
    end

    def weighted_shards(key = nil)
      @algorithm.shard_weights(shard_maps, key)
    end
  end
end
