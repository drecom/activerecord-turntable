module ActiveRecord::Turntable
  class DefaultShard < Shard
    def initialize(klass)
      (klass and original_connection_pool(klass)) or
        raise DefaultShardNotConnected, "connection_pool is nil"
      @klass = klass
      @name  = "master"
    end

    def connection_pool
      if ActiveRecord::Base == @klass
        ActiveRecord::Base.connection_pool
      else
        # use original parent class connection which is turntable disabled
        original_connection_pool
      end
    end

    private

      def original_connection_pool(klass = @klass)
        candidate_connection_pool = nil
        until candidate_connection_pool
          if klass == ActiveRecord::Base || !klass.turntable_enabled?
            candidate_connection_pool = klass.connection_pool
          else
            klass = klass.superclass
          end
        end
        candidate_connection_pool
      end
  end
end
