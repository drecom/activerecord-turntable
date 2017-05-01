module ActiveRecord::Turntable
  class SlaveRegistry
    extend ActiveSupport::PerThreadRegistry

    attr_accessor :use_slave

    def initialize
      @registry = Hash.new { |h, k| h[k] = {} }
    end

    def slave_for(shard)
      @registry[shard][:current_slave]
    end

    def set_slave_for(shard, target_slave)
      @registry[shard][:current_slave] = target_slave
    end
  end
end
