# -*- coding: utf-8 -*-
module ActiveRecord::Turntable::Algorithm
  class ModuloAlgorithm < Base
    def initialize(config)
      @config = config
    end

    def calculate(key)
      @config["shards"][key % @config["shards"].size]["connection"]
    rescue
      raise ActiveRecord::Turntable::CannotSpecifyShardError, "cannot specify shard for key:#{key}"
    end
  end
end
