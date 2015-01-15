#
# force TestFixtures to begin transaction with all shards.
#
require 'active_record/fixtures'
module ActiveRecord
  class FixtureSet
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

          ActiveRecord::Turntable::Base.force_transaction_all_shards!(:requires_new => true) do
            fixture_sets.each do |fs|
              conn = fs.model_class.respond_to?(:connection) ? fs.model_class.connection : connection
              table_rows = fs.table_rows

              table_rows.each_key do |table|
                conn.delete "DELETE FROM #{conn.quote_table_name(table)}", 'Fixture Delete'
              end

              table_rows.each do |fixture_set_name, rows|
                rows.each do |row|
                  conn.insert_fixture(row, fixture_set_name)
                end
              end
            end

            # Cap primary key sequences to max(pk).
            if connection.respond_to?(:reset_pk_sequence!)
              fixture_sets.each do |fs|
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

  module TestFixtures
    extend ActiveRecord::Turntable::Util

    def setup_fixtures(config = ActiveRecord::Base)
      return unless !ActiveRecord::Base.configurations.blank?

      if pre_loaded_fixtures && !use_transactional_fixtures
        raise RuntimeError, 'pre_loaded_fixtures requires use_transactional_fixtures'
      end

      @fixture_cache = {}
      @fixture_connections = []
      @@already_loaded_fixtures ||= {}

      # Load fixtures once and begin transaction.
      if run_in_transaction?
        if @@already_loaded_fixtures[self.class]
          @loaded_fixtures = @@already_loaded_fixtures[self.class]
        else
          @loaded_fixtures = turntable_load_fixtures(config)
          @@already_loaded_fixtures[self.class] = @loaded_fixtures
        end
        ActiveRecord::Base.force_connect_all_shards!
        @fixture_connections = enlist_fixture_connections
        @fixture_connections.each do |connection|
          connection.begin_transaction joinable: false
        end
      # Load fixtures for every test.
      else
        ActiveRecord::Fixtures.reset_cache
        @@already_loaded_fixtures[self.class] = nil
        @loaded_fixtures = turntable_load_fixtures(config)
      end

      # Instantiate fixtures for every test if requested.
      turntable_instantiate_fixtures(config) if use_instantiated_fixtures
    end

    def enlist_fixture_connections
      ActiveRecord::Base.connection_handler.connection_pool_list.map(&:connection) +
        ActiveRecord::Base.turntable_connections.values.map(&:connection)
    end

    private

    def turntable_load_fixtures(config)
      if ar41_or_later?
        load_fixtures(config)
      else
        load_fixtures
      end
    end

    def turntable_instantiate_fixtures(config)
      if ar41_or_later?
        instantiate_fixtures(config)
      else
        instantiate_fixtures
      end
    end
  end
end
