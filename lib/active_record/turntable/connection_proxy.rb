require 'active_record/turntable/connection_proxy/mixable'
module ActiveRecord::Turntable
  class ConnectionProxy
    include Mixable

    attr_writer :spec

    def initialize(cluster, options = {})
      @cluster      =  cluster
      @model_class  =  cluster.klass
      @current_shard =  (cluster.master || cluster.shards.first[1])
      @fixed_shard  = false
      @mixer = ActiveRecord::Turntable::Mixer.new(self)
    end

    delegate :logger, :to => ActiveRecord::Base

    delegate :create_table, :rename_table, :drop_table, :add_column, :remove_colomn,
      :change_column, :change_column_default, :rename_column, :add_index,
      :remove_index, :initialize_schema_information,
      :dump_schema_information, :execute_ignore_duplicate, :to => :master_connection

    # delegate :insert_many, :to => :master # ar-extensions bulk insert support

    def transaction(options = {}, &block)
      connection.transaction(options, &block)
    end

    def shards_transaction(shards, options = {}, in_recursion = false, &block)
      shards = in_recursion ? shards : Array.wrap(shards).dup
      shard_or_object = shards.shift
      shard = to_shard(shard_or_object)
      if shards.present?
        shard.connection.transaction(options) do
          shards_transaction(shards, options, true, &block)
        end
      else
        shard.connection.transaction(options) do
          block.call
        end
      end
    end

    def to_shard(shard_or_object)
      case shard_or_object
      when ActiveRecord::Turntable::Shard
        shard_or_object
      when ActiveRecord::Base
        shard_or_object.turntable_shard
      else
        raise ActiveRecord::Turntable::Error,
                "transaction cannot call to object: #{shard_or_object}"
      end
    end

    def method_missing(method, *args, &block)
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

    # for 3.2.2
    def to_sql(arel, binds = [])
      if master.connection.method(:to_sql).arity < 0
        master.connection.to_sql(arel, binds)
      else
        master.connection.to_sql(arel)
      end
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
      @fixed_shard
    end

    def master
      @cluster.master
    end

    def master_connection
      master.connection
    end

    def seq
      @cluster.seq
    end

    def current_shard
      @current_shard
    end

    def current_shard=(shard)
      logger.debug { "Chainging #{@model_class}'s shard to #{shard.name}"}
      @current_shard = shard
    end

    def connection
      @current_shard.connection
    end

    def connection_pool
      @current_shard.connection_pool
    end

    def with_shard(shard)
      old_shard, old_fixed = current_shard, fixed_shard
      self.current_shard = shard
      @fixed_shard = shard
      yield
    ensure
      @fixed_shard = old_fixed
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

    def with_master(&block)
      with_shard(@cluster.master) do
        yield
      end
    end

    def connected?
      connection_pool.connected?
    end

    if ActiveRecord::VERSION::STRING > '3.1'
      %w(columns columns_hash column_defaults primary_keys).each do |name|
        define_method(name.to_sym) do
          master.connection_pool.send(name.to_sym)
        end
      end

      if ActiveRecord::VERSION::STRING < '3.2'
        %w(table_exists?).each do |name|
          define_method(name.to_sym) do |*args|
            master.connection_pool.send(name.to_sym, *args)
          end
        end
      else
        %w(table_exists?).each do |name|
          define_method(name.to_sym) do |*args|
            master.connection_pool.with_connection do |c|
              c.schema_cache.send(name.to_sym, *args)
            end
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
  end
end
