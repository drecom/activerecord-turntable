require 'active_record/tasks/database_tasks'

module ActiveRecord
  module Tasks
    module DatabaseTasks
      def current_config(options = {})
        options.reverse_merge! :env => env
        if options.has_key?(:config)
          @current_config = options[:config]
        else
          @current_config ||= if ENV['DATABASE_URL']
                                database_url_config
                              else
                                ActiveRecord::Base.configurations[options[:env]]
                              end
        end
      end

      def charset_current(environment = env)
        charset ActiveRecord::Base.configurations[environment]
      end

      def charset(*arguments)
        configuration = arguments.first
        class_for_adapter(configuration['adapter']).new(*arguments).charset
      end

      def collation_current(environment = env)
        collation ActiveRecord::Base.configurations[environment]
      end

      def collation(*arguments)
        configuration = arguments.first
        class_for_adapter(configuration['adapter']).new(*arguments).collation
      end

      def purge(configuration)
        class_for_adapter(configuration['adapter']).new(configuration).purge
      end

      def structure_dump(*arguments)
        configuration = arguments.first
        filename = arguments.delete_at 1
        class_for_adapter(configuration['adapter']).new(*arguments).structure_dump(filename)
      end

      def structure_load(*arguments)
        configuration = arguments.first
        filename = arguments.delete_at 1
        class_for_adapter(configuration['adapter']).new(*arguments).structure_load(filename)
      end

      private

      def database_url_config
        @database_url_config ||=
               ConnectionAdapters::ConnectionSpecification::Resolver.new(ENV["DATABASE_URL"], {}).spec.config.stringify_keys
      end

      def class_for_adapter(adapter)
        key = @tasks.keys.detect { |pattern| adapter[pattern] }
        unless key
          raise DatabaseNotSupported, "Rake tasks not supported by '#{adapter}' adapter"
        end
        @tasks[key]
      end

      def each_current_configuration(environment)
        environments = [environment]
        environments << 'test' if environment == 'development'

        configurations = ActiveRecord::Base.configurations.values_at(*environments)
        configurations.compact.each do |configuration|
          shards = [configuration]
          shards += configuration['shards'].try(:values).to_a
          shards += configuration['seq'].try(:values).to_a
          shards.each do |shard|
            yield shard unless shard['database'].blank?
          end
        end
      end

      def each_local_configuration
        ActiveRecord::Base.configurations.each_value do |configuration|
          shards = [configuration]
          shards += configuration['shards'].try(:values).to_a
          shards += configuration['seq'].try(:values).to_a

          shards.each do |shard|
            next unless shard['database']
            if local_database?(shard)
              yield shard
            else
              $stderr.puts "This task only modifies local databases. #{shard['database']} is on a remote host."
            end
          end
        end
      end
    end
  end
end
