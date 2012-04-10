module ActiveRecord::Turntable
  class Mixer
    class Fader
      class SelectShardsMergeResult < Fader
        def execute
          res = @shards_query_hash.map do |shard, query|
            args = @args.dup
            args[1] = args[1].dup if args[1].present?
            shard.connection.send(@called_method, query, *args, &@block)
          end.flatten(1).compact

          case @called_method
          when "select_value", "select_one"
            res.first if res
          else
            res
          end
        end
      end
    end
  end
end
