module ActiveRecord::Turntable
  class Mixer
    class Fader
      class SpecifiedShard < Fader
        def execute
          shard, query = @shards_query_hash.first
          shard.connection.send(@called_method, query, *@args, &@block)
        end
      end
    end
  end
end
