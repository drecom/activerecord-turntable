module ActiveRecord::Turntable
  class MasterShard < Shard
    def initialize(klass)
      (klass and klass.connection_pool) or
        raise MasterShardNotConnected, "connection_pool is nil"
      @klass = klass
      @name  = "master"
    end

    def connection_pool
      if ActiveRecord::Base == @klass
        ActiveRecord::Base.connection_pool
      else
        # use parentclass connection which is turntable disabled
        klass = @klass.superclass
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
end
