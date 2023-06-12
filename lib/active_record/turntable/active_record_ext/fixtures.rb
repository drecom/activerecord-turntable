#
# force TestFixtures to begin transaction with all shards.
#
require "active_record/fixtures"
require "active_record/turntable/util"

module ActiveRecord
  class FixtureSet
    extend ActiveRecord::Turntable::Util

    # rubocop:disable Style/MultilineMethodCallBraceLayout
    unless ar52_or_later?
      def self.create_fixtures(fixtures_directory, fixture_set_names, class_names = {}, config = ActiveRecord::Base)
        fixture_set_names = Array(fixture_set_names).map(&:to_s)
        class_names = ClassCache.new class_names, config

        # FIXME: Apparently JK uses this.
        connection = block_given? ? yield : ActiveRecord::Base.connection

        files_to_read = fixture_set_names.reject { |fs_name|
          fixture_is_cached?(connection, fs_name)
        }

        unless files_to_read.empty?
          connection.disable_referential_integrity do
            fixtures_map = {}

            fixture_sets = files_to_read.map do |fs_name|
              klass = class_names[fs_name]
              conn = klass ? klass.connection : connection
              fixtures_map[fs_name] = new( # ActiveRecord::FixtureSet.new
                conn,
                fs_name,
                klass,
                ::File.join(fixtures_directory, fs_name))
            end

            update_all_loaded_fixtures fixtures_map

            ActiveRecord::Base.force_transaction_all_shards!(requires_new: true) do
              deleted_tables = Hash.new { |h, k| h[k] = Set.new }
              fixture_sets.each do |fs|
                conn = fs.model_class.respond_to?(:connection) ? fs.model_class.connection : connection
                table_rows = fs.table_rows

                table_rows.each_key do |table|
                  unless deleted_tables[conn].include? table
                    conn.delete "DELETE FROM #{conn.quote_table_name(table)}", "Fixture Delete"
                  end
                  deleted_tables[conn] << table
                end

                table_rows.each do |fixture_set_name, rows|
                  rows.each do |row|
                    conn.insert_fixture(row, fixture_set_name)
                  end
                end

                # Cap primary key sequences to max(pk).
                if connection.respond_to?(:reset_pk_sequence!)
                  connection.reset_pk_sequence!(fs.table_name)
                end
              end
            end

            cache_fixtures(connection, fixtures_map)
          end
        end
        cached_fixtures(connection, fixture_set_names)
      end
    end
    # rubocop:enable Style/MultilineMethodCallLayout
  end

  module TestFixtures
    # rubocop:disable Style/ClassVars, Style/RedundantException
    def setup_fixtures(config = ActiveRecord::Base)
      if pre_loaded_fixtures && !use_transactional_fixtures
        raise RuntimeError, "pre_loaded_fixtures requires use_transactional_fixtures"
      end

      @fixture_cache = {}
      @fixture_connections = []
      @@already_loaded_fixtures ||= {}
      @connection_subscriber = nil
      @legacy_saved_pool_configs = Hash.new { |hash, key| hash[key] = {} }
      @saved_pool_configs = Hash.new { |hash, key| hash[key] = {} }

      # Load fixtures once and begin transaction.
      if run_in_transaction?
        if @@already_loaded_fixtures[self.class]
          @loaded_fixtures = @@already_loaded_fixtures[self.class]
        else
          @loaded_fixtures = load_fixtures(config)
          @@already_loaded_fixtures[self.class] = @loaded_fixtures
        end

        # Begin transactions for connections already established
        ActiveRecord::Base.force_connect_all_shards!
        @fixture_connections = enlist_fixture_connections
        @fixture_connections.each do |connection|
          connection.begin_transaction joinable: false
          if ActiveRecord::Turntable::Util.ar51_or_later?
            connection.pool.lock_thread = true
          end
        end

        if ActiveRecord::Turntable::Util.ar51_or_later?
          # When connections are established in the future, begin a transaction too
          @connection_subscriber = ActiveSupport::Notifications.subscribe("!connection.active_record") do |_, _, _, _, payload|
            spec_name = payload[:spec_name] if payload.key?(:spec_name)
            if ActiveRecord::Turntable::Util.ar61_or_later?
              shard = payload[:shard] if payload.key?(:shard)
              setup_shared_connection_pool if ActiveRecord::Base.legacy_connection_handling
            end

            if spec_name
              begin
                if ActiveRecord::Turntable::Util.ar61_or_later?
                  connection = ActiveRecord::Base.connection_handler.retrieve_connection(spec_name, shard: shard)
                else
                  connection = ActiveRecord::Base.connection_handler.retrieve_connection(spec_name)
                end
              rescue ConnectionNotEstablished
                connection = nil
              end

              if connection
                if ActiveRecord::Turntable::Util.ar61_or_later?
                  setup_shared_connection_pool unless ActiveRecord::Base.legacy_connection_handling
                end

                if !@fixture_connections.include?(connection)
                  connection.begin_transaction joinable: false
                  connection.pool.lock_thread = true
                  @fixture_connections << connection
                end
              end
            end
          end
        end

      # Load fixtures for every test.
      else
        ActiveRecord::FixtureSet.reset_cache
        @@already_loaded_fixtures[self.class] = nil
        @loaded_fixtures = load_fixtures(config)
      end

      # Instantiate fixtures for every test if requested.
      instantiate_fixtures if use_instantiated_fixtures
    end
    # rubocop:enable Style/ClassVars, Style/RedundantException
  end
end
