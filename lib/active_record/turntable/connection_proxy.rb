require "active_record/turntable/connection_proxy/mixable"

module ActiveRecord::Turntable
  class ConnectionProxy
    include Mixable

    # for expiring query cache
    CLEAR_CACHE_METHODS = [:update, :insert, :delete, :exec_insert, :exec_update, :exec_delete, :insert_many].freeze

    attr_reader :klass, :default_shard, :default_current_shard
    attr_writer :spec

    def initialize(klass, options = {})
      @klass = klass
      @default_shard = DefaultShard.new(klass)
      @default_current_shard = @default_shard
      @mixer = ActiveRecord::Turntable::Mixer.new(self)
    end

    delegate :logger, to: ActiveRecord::Base

    delegate :shards_transaction, to: :cluster

    delegate :create_table, :rename_table, :drop_table, :add_column, :remove_colomn,
             :change_column, :change_column_default, :rename_column, :add_index,
             :remove_index, :initialize_schema_information,
             :dump_schema_information, :execute_ignore_duplicate,
             :query_cache_enabled, to: :default_connection

    def cluster
      klass.turntable_cluster
    end

    def transaction(options = {}, &block)
      with_master {
        connection.transaction(options, &block)
      }
    end

    def cache
      old = query_cache_enabled
      enable_query_cache!
      yield
    ensure
      unless old
        disable_query_cache!
        clear_query_cache
      end
    end

    def uncached
      old = query_cache_enabled
      disable_query_cache!
      yield
    ensure
      enable_query_cache! if old
    end

    def enable_query_cache!
      default_connection.enable_query_cache!

      cluster.shards.each do |shard|
        shard.connection.enable_query_cache!
      end
    end

    def disable_query_cache!
      default_connection.disable_query_cache!

      cluster.shards.each do |shard|
        shard.connection.disable_query_cache!
      end
    end

    def clear_query_cache_if_needed(method)
      clear_query_cache if CLEAR_CACHE_METHODS.include?(method)
    end

    def clear_query_cache
      default_connection.clear_query_cache

      cluster.shards.each do |shard|
        shard.connection.clear_query_cache
      end
    end

    # rubocop:disable Style/MethodMissing
    def method_missing(method, *args, &block)
      clear_query_cache_if_needed(method)
      if shard_fixed?
        connection.send(method, *args, &block)
      elsif mixable?(method, *args)
        fader = @mixer.build_fader(method, *args, &block)
        logger.debug {
          "[ActiveRecord::Turntable] Sending method: #{method}, " \
          "sql: #{args.first}, " \
          "shards: #{fader.shards_query_hash.keys.map(&:name)}"
        }
        fader.execute
      else
        connection.send(method, *args, &block)
      end
    end
    # rubocop:enable Style/MethodMissing

    def respond_to_missing?(method, include_private = false)
      connection.send(:respond_to?, method, include_private)
    end

    def to_sql(arel, binds = [])
      default_connection.to_sql(arel, binds)
    end

    def shards
      cluster.shards
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

    def default_connection
      default_shard.connection
    end

    def current_shard
      current_shard_entry[object_id] ||= @default_current_shard
    end

    def current_shard=(shard)
      logger.debug { "Changing #{klass}'s shard to #{shard.name}" }
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

      old_shard = current_shard
      old_fixed = fixed_shard
      self.current_shard = shard
      self.fixed_shard = shard
      yield
    ensure
      self.fixed_shard = old_fixed
      self.current_shard = old_shard
    end

    def with_recursive_shards(connection_name, *klasses, &block)
      with_shard(cluster.shard_registry[connection_name]) do
        if klasses.blank?
          yield
        else
          current_klass = klasses.shift
          current_klass.connection.with_recursive_shards(connection_name, *klasses, &block)
        end
      end
    end

    def with_master
      old = cluster.slave_enabled?
      cluster.set_slave_enabled(false)
      yield
    ensure
      cluster.set_slave_enabled(old)
    end

    def with_slave
      old = cluster.slave_enabled?
      cluster.set_slave_enabled(true)
      yield
    ensure
      cluster.set_slave_enabled(old)
    end

    # Send queries to all shards in this cluster
    # @param [Boolean] continue_on_error when a shard raises error, ignore exception and continue
    def with_all(continue_on_error = false)
      cluster.shards.map do |shard|
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

    # Send queries to default connection and all shards in this cluster
    # @param [Boolean] continue_on_error when a shard raises error, ignore exception and continue
    def with_default_and_all(continue_on_error = false)
      ([default_shard] + cluster.shards).map do |shard|
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

    def with_default_shard(&block)
      with_shard(default_shard) do
        yield
      end
    end

    delegate :connected?, :automatic_reconnect, :automatic_reconnect=, :checkout_timeout, :dead_connection_timeout,
             :spec, :connections, :size, :reaper, to: :connection_pool

    %w(columns columns_hash column_defaults primary_keys).each do |name|
      define_method(name.to_sym) do
        default_shard.connection_pool.send(name.to_sym)
      end
    end

    %w(data_source_exists?).each do |name|
      define_method(name.to_sym) do |*args|
        default_shard.connection_pool.with_connection do |c|
          c.schema_cache.send(name.to_sym, *args)
        end
      end
    end

    def columns(*args)
      if args.size > 0
        default_shard.connection_pool.columns[*args]
      else
        default_shard.connection_pool.columns
      end
    end

    def pk_and_sequence_for(*args)
      default_shard.connection.send(:pk_and_sequence_for, *args)
    end

    def primary_key(*args)
      default_shard.connection.send(:primary_key, *args)
    end

    def supports_views?(*args)
      default_shard.connection.send(:supports_views?, *args)
    end

    def spec
      @spec ||= default_shard.connection_pool.spec
    end

    private

      def fixed_shard_entry
        Thread.current[:turntable_fixed_shard] ||= Concurrent::Map.new
      end

      def current_shard_entry
        Thread.current[:turntable_current_shard] ||= Concurrent::Map.new
      end
  end
end
