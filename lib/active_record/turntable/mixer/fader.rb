# -*- coding: utf-8 -*-
module ActiveRecord::Turntable
  class Mixer
    class Fader
      # 単数shard
      autoload :SpecifiedShard, "active_record/turntable/mixer/fader/specified_shard"

      # 複数shard
      autoload :SelectShardsMergeResult, "active_record/turntable/mixer/fader/select_shards_merge_result"
      autoload :InsertShardsMergeResult, "active_record/turntable/mixer/fader/insert_shards_merge_result"
      autoload :UpdateShardsMergeResult, "active_record/turntable/mixer/fader/update_shards_merge_result"

      # count
      autoload :CalculateShardsSumResult, "active_record/turntable/mixer/fader/calculate_shards_sum_result"

      attr_reader :shards_query_hash
      attr_reader :called_method
      attr_reader :query

      def initialize(proxy, shards_query_hash, called_method, query, *args, &block)
        @proxy = proxy
        @shards_query_hash = shards_query_hash
        @called_method = called_method
        @query = query
        @args = args
        @block = block
      end

      def execute
        raise ActiveRecord::Turntable::NotImplementedError, "Called abstract method"
      end
    end
  end
end
