# -*- coding: utf-8 -*-
module ActiveRecord::Turntable
  class Mixer
    class Fader
      extend ActiveSupport::Autoload

      eager_autoload do
        # single shard
        autoload :SpecifiedShard
        # multiple shard merging
        autoload :SelectShardsMergeResult
        autoload :InsertShardsMergeResult
        autoload :UpdateShardsMergeResult
        # calculations
        autoload :CalculateShardsSumResult
      end

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
        raise NotImplementedError, "Called abstract method"
      end
    end
  end
end
