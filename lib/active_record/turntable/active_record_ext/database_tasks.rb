require 'active_record/tasks/database_tasks'

module ActiveRecord
  module Tasks
    module DatabaseTasks
      def create_current_turntable_cluster(environment = env)
        each_current_turntable_cluster_configuration(environment) { |name, configuration|
          puts "[turntable] *** executing to database: #{configuration['database']}"
          create configuration
        }
        ActiveRecord::Base.establish_connection environment.to_sym
      end

      def drop_current_turntable_cluster(environment = env)
        each_current_turntable_cluster_configuration(environment) { |name, configuration|
          puts "[turntable] *** executing to database: #{configuration['database']}"
          drop configuration
        }
      end

      def each_current_turntable_cluster_connected(environment = env)
        each_current_turntable_cluster_configuration(environment) do |name, configuration|
          ActiveRecord::Base.clear_active_connections!
          ActiveRecord::Base.establish_connection(configuration)
          yield(name, configuration)
        end
        ActiveRecord::Base.clear_active_connections!
        ActiveRecord::Base.establish_connection environment.to_sym
      end

      def each_current_turntable_cluster_configuration(environment = env)
        environments = [environment]
        environments << 'test' if environment == 'development'

        current_turntable_cluster_configurations(*environments).each do |name, configuration|
          yield(name, configuration) unless configuration['database'].blank?
        end
      end

      def current_turntable_cluster_configurations(*environments)
        environments.inject({}) do |configurations, environ|
          config = ActiveRecord::Base.configurations[environ]
          configurations.merge!(config["shards"]) if config["shards"]
          configurations.merge!(config["seq"]) if config["seq"]
        end
      end
    end
  end
end
