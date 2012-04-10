module ActiveRecord::Turntable
  class Mixer
    class Fader
      class InsertShardsMergeResult < Fader
        def execute
          if @shards_query_hash.size == 1
            @proxy.shards_transaction(@shards_query_hash.keys) do
              shard, query = @shards_query_hash.first
              shard.connection.send(@called_method, query, *@args, &@block)
            end
          else
            @proxy.shards_transaction(@shards_query_hash.keys) do
              @shards_query_hash.each do |shard, query|
                args    = @args.dup
                args[4] = args[4].dup if args[4].present?
                shard.connection.send(@called_method, query, *args, &@block)
              end
            end
          end
        end
      end
    end
  end
end
