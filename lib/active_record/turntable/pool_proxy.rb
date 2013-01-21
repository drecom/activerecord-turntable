module ActiveRecord::Turntable
  module ActiveRecordConnectionMethods
    def self.included(base)
      base.alias_method_chain :reload, :master
    end

    def reload_with_master(*args, &block)
      connection.with_master { reload_without_master }
    end
  end

  class PoolProxy
    def initialize(proxy)
      @proxy = proxy
    end

    def connection
      @proxy
    end

    def spec
      @proxy.spec
    end


    def with_connection
      yield @proxy
    end

    def connected?
      @proxy.connected?
    end

    if ActiveRecord::VERSION::STRING > '3.1'
      %w(columns_hash column_defaults primary_keys).each do |name|
        define_method(name.to_sym) do
          @proxy.send(name.to_sym)
        end
      end

      %w(table_exists? columns).each do |name|
        define_method(name.to_sym) do |*args|
          @proxy.send(name.to_sym, *args)
        end
      end
    end

    %w(disconnect! release_connection clear_all_connections! clear_active_connections! clear_reloadable_connections! clear_stale_cached_connections! verify_active_connections!).each do |name|
      define_method(name.to_sym) do
        @proxy.master.connection_pool.send(name.to_sym)
        @proxy.seq.connection_pool.try(name.to_sym) if @proxy.respond_to?(:seq)
        @proxy.shards.values.each do |pool|
          pool.connection_pool.send(name.to_sym)
        end
      end
    end
  end
end
