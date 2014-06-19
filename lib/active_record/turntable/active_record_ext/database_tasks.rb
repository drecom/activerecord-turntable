require 'active_record/tasks/database_tasks'

module ActiveRecord
  module Tasks
    module DatabaseTasks
      def create_all_turntable_cluster
        each_local_turntable_cluster_configuration { |name, configuration|
          puts "[turntable] *** executing to database: #{configuration['database']}"
          create configuration
        }
      end

      def drop_all_turntable_cluster
        each_local_turntable_cluster_configuration { |name, configuration|
          puts "[turntable] *** executing to database: #{configuration['database']}"
          drop configuration
        }
      end

      def create_current_turntable_cluster(environment = env)
        each_current_turntable_cluster_configuration(true, environment) { |name, configuration|
          puts "[turntable] *** executing to database: #{configuration['database']}"
          create configuration
        }
        ActiveRecord::Base.establish_connection environment.to_sym
      end

      def drop_current_turntable_cluster(environment = env)
        each_current_turntable_cluster_configuration(true, environment) { |name, configuration|
          puts "[turntable] *** executing to database: #{configuration['database']}"
          drop configuration
        }
      end

      def each_current_turntable_cluster_connected(with_test = false, environment = env)
        each_current_turntable_cluster_configuration(with_test, environment) do |name, configuration|
          ActiveRecord::Base.clear_active_connections!
          ActiveRecord::Base.establish_connection(configuration)
          ActiveRecord::Migration.current_shard = name
          yield(name, configuration)
        end
        ActiveRecord::Base.clear_active_connections!
        ActiveRecord::Base.establish_connection environment.to_sym
      end

      def each_current_turntable_cluster_configuration(with_test = false, environment = env)
        environments = [environment]
        environments << 'test' if with_test and environment == 'development'

        current_turntable_cluster_configurations(*environments).each do |name, configuration|
          yield(name, configuration) unless configuration['database'].blank?
        end
      end

      def each_local_turntable_cluster_configuration
        ActiveRecord::Base.configurations.keys.each do |k|
          current_turntable_cluster_configurations(k).each do |name, configuration|
            next if configuration['database'].blank?

            if local_database?(configuration)
              yield(name,configuration)
            else
              $stderr.puts "This task only modifies local databases. #{configuration['database']} is on a remote host."
            end
          end
        end
      end

      def current_turntable_cluster_configurations(*environments)
        configurations = []
        environments.each do |environ|
          config = ActiveRecord::Base.configurations[environ]
          %w(shards seq).each do |name|
            configurations += config[name].to_a
          end
        end
        configurations
      end
    end
  end
end
