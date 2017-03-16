require "zlib"

module ActiveRecord::Turntable::Algorithm
  class HashSlotAlgorithm < Base
    DEFAULT_HASH_FUNC = ->(key) { Zlib.crc32(key.to_s) }

    attr_reader :hash_func

    def initialize(config = {})
      super
      @hash_func = @config[:hash_func] || DEFAULT_HASH_FUNC
    end

    def choose(shard_maps, key)
      slot = slot_for_key(key, shard_maps.last.range.max)
      shard_map = shard_maps.bsearch { |shard| slot <= shard.range.max }
      raise ActiveRecord::Turntable::CannotSpecifyShardError, "cannot specify shard for key:#{key}" unless shard_map
      shard_map.shard
    end

    def choose_index(shard_maps, key)
      slot = slot_for_key(key, shard_maps.last.range.max)
      (0...shard_maps.size).bsearch { |idx| slot <= shard_maps[idx].range.max } or
        raise ActiveRecord::Turntable::CannotSpecifyShardError, "cannot specify shard for key:#{key}"
    end

    def slot_for_key(key, max)
      hash_func.call(key) % (max + 1)
    end

    def shard_weights(shard_maps, current_sequence_value)
      shard_maps.map { |shard_map| [shard_map.shard, shard_map.range.size] }.to_h
    end
  end
end
