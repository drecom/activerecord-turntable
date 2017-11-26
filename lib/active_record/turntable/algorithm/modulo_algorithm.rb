# -*- coding: utf-8 -*-
module ActiveRecord::Turntable::Algorithm
  class ModuloAlgorithm < Base
    def choose(shard_maps, key)
      shard_maps[key % shard_maps.size].shard
    rescue
      raise ActiveRecord::Turntable::CannotSpecifyShardError, "cannot specify shard for key:#{key.inspect}"
    end
  end
end
