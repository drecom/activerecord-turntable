module ActiveRecord::Turntable
  class ShardRegistry
    ShardMap = Struct.new(:range, :shard, :slaves) do
      delegate :connection, :connection_pool, :name, to: :shard
    end

    attr_reader :shard_maps

    def initialize
      @shards_names_hash = {}.with_indifferent_access
      @shard_maps = []
    end

    def add(setting)
      shard = (@shards_names_hash[setting.name] ||= Shard.new(setting.name, setting.slaves))
      @shard_maps << ShardMap.new(setting.range, shard)
      @shard_maps.sort_by! { |m| m.range.min }
    end

    def shards
      @shards_names_hash.values
    end
    alias_method :all, :shards

    def release!
      shards.each do |shard|
        shard.connection_pool.clear_all_connections!
      end
    end

    def [](name)
      @shards_names_hash[name]
    end
  end
end
