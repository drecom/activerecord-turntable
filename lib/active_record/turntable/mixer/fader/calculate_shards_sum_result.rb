module ActiveRecord::Turntable
  class Mixer
    class Fader
      class CalculateShardsSumResult < Fader
        def execute
          results = @shards_query_hash.map do |shard, query|
            args = @args.dup
            args[1] = args[1].dup if args[1].present?
            shard.connection.send(@called_method, query, *@args, &@block)
          end
          merge_results(results)
        end

        private

          def merge_results(results)
            ActiveRecord::Result.new(
              results.first.columns,
              results[0].rows.zip(*results[1..-1].map(&:rows)).map { |r| [r.map(&:first).inject(&:+)] },
              results.first.column_types
            )
          end
      end
    end
  end
end
