begin
  require "acts_as_archive"
  # acts_as_archive extension
  class ActsAsArchive
    class << self
      # @note use the same shard which `from` shard using
      def move_with_turntable(config, where, merge_options = {})
        if [config[:to], config[:from]].all? { |k| k.try(:turntable_enabled?) }
          current_shard = config[:from].connection.current_shard.name.to_sym
          config[:to].connection.with_shard(current_shard) {
            move_without_turntable(config, where, merge_options)
          }
        else
          move_without_turntable(config, where, merge_options)
        end
      end

      alias_method_chain :move, :turntable
    end
  end
rescue LoadError
end
