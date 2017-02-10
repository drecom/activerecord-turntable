module ActiveRecord::Turntable
  module ActiveRecordExt
    module ActsAsArchiveExt
      def self.prepended(base)
        class << base
          prepend ClassMethods
        end
      end

      module ClassMethods
        # @note use the same shard which `from` shard using
        def move(config, where, merge_options = {})
          if [config[:to], config[:from]].all? { |k| k.try(:turntable_enabled?) }
            current_shard = config[:from].connection.current_shard.name.to_sym
            config[:to].connection.with_shard(current_shard) {
              super
            }
          else
            super
          end
        end
      end
    end

    begin
      require "acts_as_archive"
      ActsAsArchive.prepend ActsAsArchiveExt
    rescue LoadError
    end
  end
end
