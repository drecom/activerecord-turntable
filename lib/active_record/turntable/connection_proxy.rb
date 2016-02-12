require 'active_record/turntable/connection_proxy/mixable'
module ActiveRecord::Turntable
  class ConnectionProxy
    include Mixable

    # for expiring query cache
    CLEAR_CACHE_METHODS = [:update, :insert, :delete, :exec_insert, :exec_update, :exec_delete, :insert_many]

    attr_reader :klass
    attr_writer :spec

    def initialize(klass, cluster, options = {})
      @klass   = klass
      @cluster = cluster
      @master_shard = MasterShard.new(klass)
      @default_current_shard = @master_shard
      @mixer = ActiveRecord::Turntable::Mixer.new(self)
    end

    delegate :logger, to: ActiveRecord::Base

    delegate :shards_transaction, to: :cluster

    delegate :create_table, :rename_table, :drop_table, :add_column, :remove_colomn,
      :change_column, :change_column_default, :rename_column, :add_index,
      :remove_index, :initialize_schema_information,
      :dump_schema_information, :execute_ignore_duplicate, to: :master_connection

    def transaction(options = {}, &block)
      connection.transaction(options, &block)
    end

    def cache
      enable_query_cache!
      yield
    ensure
      clear_query_cache
    end

    def enable_query_cache!
      klass.turntable_connections.each do |k,v|
        v.connection.enable_query_cache!
      end
    end

    def clear_query_cache_if_needed(method)
      clear_query_cache if CLEAR_CACHE_METHODS.include?(method)
    end

    def clear_query_cache
      klass.turntable_connections.each do |k,v|
        v.connection.clear_query_cache
      end
    end

    def method_missing(method, *args, &block)
      clear_query_cache_if_needed(method)
      if shard_fixed?
        connection.send(method, *args, &block)
      elsif mixable?(method, *args)
        fader = @mixer.build_fader(method, *args, &block)
        logger.debug { "[ActiveRecord::Turntable] Sending method: #{method}, " +
          "sql: #{args.first}, " +
          "shards: #{fader.shards_query_hash.keys.map(&:name)}" }
        fader.execute
      else
        connection.send(method, *args, &block)
      end
    end

    def respond_to_missing?(method, include_private = false)
      connection.send(:respond_to?, method, include_private)
    end

    def to_sql(arel, binds = [])
      master.connection.to_sql(arel, binds)
    end

    def cluster
      @cluster
    end

    def shards
      @cluster.shards
    end

    def shard_fixed?
      !!fixed_shard
    end

    def fixed_shard
      fixed_shard_entry[object_id]
    end

    def fixed_shard=(shard)
      fixed_shard_entry[object_id] = shard
    end

    def master
      @master_shard
    end

    def master_connection
      master.connection
    end

    def seq
      @cluster.seq || master
    end

    def current_shard
      current_shard_entry[object_id] ||= @default_current_shard
    end

    def current_shard=(shard)
      logger.debug { "Changing #{klass}'s shard to #{shard.name}"}
      current_shard_entry[object_id] = shard
    end

    # @return connection of current shard
    def connection
      current_shard.connection
    end

    # @return connection_pool of current shard
    def connection_pool
      current_shard.connection_pool
    end

    # Fix connection to given shard in block
    # @param [ActiveRecord::Base, Symbol, ActiveRecord::Turntable::Shard, Numeric, String] shard which you want to fix
    # @param shard [ActiveRecord::Base] AR Object
    # @param shard [Symbol] shard name symbol that defined in turntable.yml
    # @param shard [ActiveRecord::Turntable::Shard] Shard object
    # @param shard [String, Numeric] Raw sharding id
    def with_shard(shard)
      shard = cluster.to_shard(shard)

      old_shard, old_fixed = current_shard, fixed_shard
      self.current_shard = shard
      self.fixed_shard = shard
      yield
    ensure
      self.fixed_shard = old_fixed
      self.current_shard = old_shard
    end

    def with_recursive_shards(connection_name, *klasses, &block)
      with_shard(shards[connection_name]) do
        if klasses.blank?
          yield
        else
          current_klass = klasses.shift
          current_klass.connection.with_recursive_shards(connection_name, *klasses, &block)
        end
      end
    end

    # Send queries to all shards in this cluster
    # @param [Boolean] continue_on_error when a shard raises error, ignore exception and continue
    def with_all(continue_on_error = false)
      @cluster.shards.values.map do |shard|
        begin
          with_shard(shard) {
            yield
          }
        rescue Exception => err
          unless continue_on_error
            raise err
          end
          err
        end
      end
    end

    # Send queries to master connection and all shards in this cluster
    # @param [Boolean] continue_on_error when a shard raises error, ignore exception and continue
    def with_master_and_all(continue_on_error = false)
      ([master] + @cluster.shards.values).map do |shard|
        begin
          with_shard(shard) {
            yield
          }
        rescue Exception => err
          unless continue_on_error
            raise err
          end
          err
        end
      end
    end

    def with_master(&block)
      with_shard(master) do
        yield
      end
    end

    delegate :connected?, :automatic_reconnect, :automatic_reconnect=, :checkout_timeout, :dead_connection_timeout,
               :spec, :connections, :size, :reaper, :table_exists?, to: :connection_pool

    %w(columns columns_hash column_defaults primary_keys).each do |name|
      define_method(name.to_sym) do
        master.connection_pool.send(name.to_sym)
      end
    end

    %w(table_exists?).each do |name|
      define_method(name.to_sym) do |*args|
        master.connection_pool.with_connection do |c|
          c.schema_cache.send(name.to_sym, *args)
        end
      end
    end

    def columns(*args)
      if args.size > 0
        master.connection_pool.columns[*args]
      else
        master.connection_pool.columns
      end
    end

    def pk_and_sequence_for(*args)
      master.connection.send(:pk_and_sequence_for, *args)
    end

    def primary_key(*args)
      master.connection.send(:primary_key, *args)
    end

    def supports_views?(*args)
      master.connection.send(:supports_views?, *args)
    end

    def spec
      @spec ||= master.connection_pool.spec
    end

    private

    def fixed_shard_entry
      Thread.current[:turntable_fixed_shard] ||= ThreadSafe::Cache.new
    end

    def current_shard_entry
      Thread.current[:turntable_current_shard] ||= ThreadSafe::Cache.new
    end
  end
end
