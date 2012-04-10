# -*- coding: utf-8 -*-
module ActiveRecord::Turntable::Algorithm
  class RangeAlgorithm < Base
    def initialize(config)
      @config = config
    end

    def calculate(key)
      idx = calculate_idx(key)
      @config["shards"][idx]["connection"]
    rescue
      raise ActiveRecord::Turntable::CannotSpecifyShardError, "cannot specify shard for key:#{key}"
    end

    def calculate_idx(key)
      @config["shards"].find_index {|h| h["less_than"] > key }
    end

    # { connection_name => weight, ... }
    def calculate_used_shards_with_weight(sequence_value)
      idx = calculate_idx(sequence_value)
      last_connection = calculate(sequence_value)
      shards = @config["shards"][0..idx]
      weighted_hash = Hash.new {|h,k| h[k]=0}
      prev_max = 0
      shards.each_with_index do |h,idx|
        weighted_hash[h["connection"]] += if idx < shards.size - 1
                                            h["less_than"] - prev_max - 1
                                          else
                                            sequence_value - prev_max
                                          end
        prev_max = h["less_than"] - 1
      end
      return weighted_hash
    end
  end
end
