require "active_record/tasks/database_tasks"

module ActiveRecord
  module Tasks
    module DatabaseTasks
      def create_all_turntable_cluster
        each_local_turntable_cluster_configuration { |_name, configuration|
          puts "[turntable] *** executing to database: #{configuration['database']}"
          create configuration
        }
      end

      def drop_all_turntable_cluster
        each_local_turntable_cluster_configuration { |_name, configuration|
          puts "[turntable] *** executing to database: #{configuration['database']}"
          drop configuration
        }
      end

      def create_current_turntable_cluster(environment = env)
        each_current_turntable_cluster_configuration(environment) { |_name, configuration|
          puts "[turntable] *** executing to database: #{configuration['database']}"
          create configuration
        }
        ActiveRecord::Base.establish_connection environment.to_sym
      end

      def drop_current_turntable_cluster(environment = env)
        each_current_turntable_cluster_configuration(environment) { |_name, configuration|
          puts "[turntable] *** executing to database: #{configuration['database']}"
          drop configuration
        }
      end

      def each_current_turntable_cluster_connected(environment)
        old_connection_pool = ActiveRecord::Base.connection_pool
        each_current_turntable_cluster_configuration(environment) do |name, configuration|
          ActiveRecord::Base.clear_active_connections!
          ActiveRecord::Base.establish_connection(configuration)
          ActiveRecord::Migration.current_shard = name
          yield(name, configuration)
        end
        ActiveRecord::Base.clear_active_connections!
        if ActiveRecord::Turntable::Util.ar61_or_later?
          ActiveRecord::Base.establish_connection old_connection_pool.db_config
        else
          ActiveRecord::Base.establish_connection old_connection_pool.spec.config
        end
      end

      def each_current_turntable_cluster_configuration(environment)
        environments = [environment]
        environments << "test" if environment == "development"

        current_turntable_cluster_configurations(*environments).each do |name, configuration|
          yield(name, configuration) unless configuration["database"].blank?
        end
      end

      def each_local_turntable_cluster_configuration
        ActiveRecord::Base.configurations.keys.each do |k|
          current_turntable_cluster_configurations(k).each do |name, configuration|
            next if configuration["database"].blank?

            if local_database?(configuration)
              yield(name, configuration)
            else
              $stderr.puts "This task only modifies local databases. #{configuration['database']} is on a remote host."
            end
          end
        end
      end

      def current_turntable_cluster_configurations(*environments)
        configurations = []
        environments.each do |environ|
          if ActiveRecord::Turntable::Util.ar61_or_later?
            config = ActiveRecord::Base.configurations.configs_for(env_name: environ, name: "primary")
          else
            config = ActiveRecord::Base.configurations[environ]
          end
          next unless config

          if ActiveRecord::Turntable::Util.ar61_or_later?
            [:shards, :seq].each do |name|
              configurations += config.configuration_hash[name].to_a if config.configuration_hash.has_key?(name)
            end
          else
            %w(shards seq).each do |name|
              configurations += config[name].to_a if config.has_key?(name)
            end
          end
        end
        configurations
      end
    end
  end
end
