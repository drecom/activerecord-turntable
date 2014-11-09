module ActiveRecord::Turntable
  class Mixer
    class Fader
      class SpecifiedShard < Fader
        def execute
          shard, query = @shards_query_hash.first
          @proxy.with_shard(shard) do
            shard.connection.send(@called_method, query, *@args, &@block)
          end
        end
      end
    end
  end
end
