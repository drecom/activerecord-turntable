module ActiveRecord::Turntable
  module Helpers
    module TestHelper
      # all shards
      def FabricateAll(name, overrides = {}, &block)
        obj = Fabrication::Fabricator.generate(name, {
          save: true,
        }, overrides, &block)

        default_pool = obj.class.connection_pool
        connection_pools = obj.class.connection_handler.instance_variable_get(:@connection_pools)

        ActiveRecord::Base.turntable_connections.each do |_conn_name, conn|
          new_obj = obj.dup
          connection_pools[new_obj.class.name] = conn
          new_obj.id = obj.id
          new_obj.send(:create)
        end
        obj
      ensure
        connection_pools[obj.class.name] = default_pool
      end
    end
  end
end
