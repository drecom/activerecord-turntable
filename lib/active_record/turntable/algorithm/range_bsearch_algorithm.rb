# -*- coding: utf-8 -*-
require "bsearch"
module ActiveRecord::Turntable::Algorithm
  class RangeBsearchAlgorithm < Base
    def initialize(config)
      @config = config
      @config[:shards].sort_by! { |a| a[:less_than] }
    end

    def calculate(key)
      idx = calculate_idx(key)
      @config[:shards][idx][:connection]
    rescue
      raise ActiveRecord::Turntable::CannotSpecifyShardError, "cannot specify shard for key:#{key}"
    end

    def calculate_idx(key)
      @config[:shards].bsearch_upper_boundary { |h|
        h[:less_than] <=> key
      }
    end

    # { connection_name => weight, ... }
    def calculate_used_shards_with_weight(sequence_value)
      current_shard_idx = calculate_idx(sequence_value)
      last_connection = calculate(sequence_value)
      shards = @config[:shards][0..current_shard_idx]
      weighted_hash = Hash.new { |h, k| h[k] = 0 }
      prev_max = 0
      shards.each_with_index do |h, idx|
        weighted_hash[h[:connection]] += if idx < shards.size - 1
                                           h[:less_than] - prev_max - 1
                                         else
                                           sequence_value - prev_max
                                         end
        prev_max = h[:less_than] - 1
      end
      weighted_hash
    end
  end
end
