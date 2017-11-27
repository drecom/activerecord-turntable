require "active_record/turntable/shard"

module ActiveRecord::Turntable
  class SlaveShard < Shard
    def support_slave?
      false
    end
  end
end
