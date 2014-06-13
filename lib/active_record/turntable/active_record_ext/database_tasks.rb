require 'active_record/tasks/database_tasks'

module ActiveRecord
  module Tasks
    module DatabaseTasks
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
