module ActiveRecord::Turntable::Algorithm
  class Base
    def initialize(config = {})
      @config = config
    end

    def choose(shard_maps, key)
      raise NotImplementedError, "not implemented"
    end

    def shard_weights(shard_maps, current_sequence_value)
      raise NotImplementedError, "not implemented"
    end
  end
end
