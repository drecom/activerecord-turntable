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

    attr_reader :proxy
    alias_method :connection, :proxy

    def with_connection
      yield proxy
    end

    delegate :connected?, :automatic_reconnect, :automatic_reconnect=, :checkout_timeout, :dead_connection_timeout,
             :spec, :connections, :size, :reaper, :table_exists?, to: :proxy

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

    %w(active_connection?).each do |name|
      define_method(name.to_sym) do |*_args|
        @proxy.master.connection_pool.send(name.to_sym) ||
          @proxy.seq.connection_pool.try(name.to_sym) if @proxy.respond_to?(:seq) ||
                                                         @proxy.shards.values.any? do |pool|
                                                           pool.connection_pool.send(name.to_sym)
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
