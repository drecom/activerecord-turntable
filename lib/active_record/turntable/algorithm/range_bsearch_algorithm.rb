module ActiveRecord::Turntable::Algorithm
  class RangeBsearchAlgorithm < Base
    def choose(shard_maps, key)
      shard_map = shard_maps.bsearch { |shard| key <= shard.range.max }
      raise ActiveRecord::Turntable::CannotSpecifyShardError, "cannot specify shard for key:#{key.inspect}" unless shard_map
      shard_map.shard
    end

    def choose_index(shard_maps, key)
      (0...shard_maps.size).bsearch { |idx| key <= shard_maps[idx].range.max } or
        raise ActiveRecord::Turntable::CannotSpecifyShardError, "cannot specify shard for key:#{key.inspect}"
    end

    def shard_weights(shard_maps, current_sequence_value)
      current_shard_index = choose_index(shard_maps, current_sequence_value)
      shard_maps = shard_maps[0..current_shard_index]
      weights_hash = Hash.new { |h, k| h[k] = 0 }
      shard_maps.each_with_index do |shard_map, idx|
        weights_hash[shard_map.shard] += if idx < current_shard_index
                                           shard_map.range.size
                                         else
                                           current_sequence_value - shard_map.range.min + 1
                                         end
      end
      weights_hash
    end
  end
end
