module ActiveRecord::Turntable
  class Mixer
    class Fader
      class CalculateShardsSumResult < Fader
        def execute
          @shards_query_hash.map do |shard, query|
            args = @args.dup
            args[1] = args[1].dup if args[1].present?
            shard.connection.send(@called_method, query, *@args, &@block)
          end.inject(&:+)
        end
      end
    end
  end
end
