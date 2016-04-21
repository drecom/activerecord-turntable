require "active_record/turntable"
ActiveRecord::SchemaDumper.send(:include, ActiveRecord::Turntable::ActiveRecordExt::SchemaDumper)

turntable_namespace = nil

db_namespace = namespace :db do
  turntable_namespace = namespace :turntable do
    namespace :create do
      task :all do
        ActiveRecord::Tasks::DatabaseTasks.create_all_turntable_cluster
      end
    end

    desc "Create current turntable databases config/database.yml for the current Rails.env"
    task :create do
      unless ENV["DATABASE_URL"]
        ActiveRecord::Tasks::DatabaseTasks.create_current_turntable_cluster
      end
    end

    namespace :drop do
      task :all do
        ActiveRecord::Tasks::DatabaseTasks.drop_all_turntable_cluster
      end
    end

    desc "Drops current turntable databases for the current Rails.env"
    task :drop do
      unless ENV["DATABASE_URL"]
        ActiveRecord::Tasks::DatabaseTasks.drop_current_turntable_cluster
      end
    end

    namespace :schema do
      # TODO: implement schema:cache:xxxx
      task :dump do
        require "active_record/schema_dumper"
        config = ActiveRecord::Base.configurations[Rails.env]
        shard_configs = config["shards"]
        shard_configs.merge!(config["seq"]) if config["seq"]
        if shard_configs
          shard_configs.each do |name, config|
            next unless config["database"]
            filename = ENV["SCHEMA"] || "#{Rails.root}/db/schema-#{name}.rb"
            File.open(filename, "w:utf-8") do |file|
              ActiveRecord::Base.establish_connection(config)
              ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
            end
          end
        end
        ActiveRecord::Base.establish_connection(config)
        turntable_namespace["schema:dump"].reenable
      end

      desc "Load a schema.rb file into the database"
      task :load do
        config = ActiveRecord::Base.configurations[Rails.env]
        shard_configs = config["shards"]
        shard_configs.merge!(config["seq"]) if config["seq"]
        if shard_configs
          shard_configs.each do |name, config|
            next unless config["database"]
            ActiveRecord::Base.establish_connection(config)
            file = ENV["SCHEMA"] || "#{Rails.root}/db/schema-#{name}.rb"
            if File.exist?(file)
              load(file)
            else
              abort %(#{file} doesn't exist yet. Run "rake db:migrate" to create it then try again. If you do not intend to use a database, you should instead alter #{Rails.root}/config/application.rb to limit the frameworks that will be loaded')
            end
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end

    namespace :structure do
      desc "Dump the database structure to an SQL file"
      task :dump do
        current_config = ActiveRecord::Tasks::DatabaseTasks.current_config
        shard_configs = current_config["shards"]
        shard_configs.merge!(current_config["seq"]) if current_config["seq"]
        if shard_configs
          shard_configs.each do |name, config|
            next unless config["database"]
            ActiveRecord::Base.establish_connection(config)
            filename = File.join(ActiveRecord::Tasks::DatabaseTasks.db_dir, "structure_#{name}.sql")
            ActiveRecord::Tasks::DatabaseTasks.structure_dump(config, filename)

            next unless ActiveRecord::Base.connection.supports_migrations?
            File.open(filename, "a") do |f|
              f.puts ActiveRecord::Base.connection.dump_schema_information
            end
          end
          ActiveRecord::Base.establish_connection(current_config)
        end
        turntable_namespace["structure:dump"].reenable
      end

      # desc "Recreate the databases from the structure.sql file"
      task :load do
        current_config = ActiveRecord::Tasks::DatabaseTasks.current_config
        shard_configs = current_config["shards"]
        shard_configs.merge!(current_config["seq"]) if current_config["seq"]
        if shard_configs
          shard_configs.each do |name, config|
            next unless config["database"]
            ActiveRecord::Base.establish_connection(config)
            filename = File.join(ActiveRecord::Tasks::DatabaseTasks.db_dir, "structure_#{name}.sql")
            ActiveRecord::Tasks::DatabaseTasks.structure_load(config, filename)
          end
          ActiveRecord::Base.establish_connection(current_config)
        end
      end
    end

    namespace :test do
      # desc "Empty the test database"
      task :purge do
        config = ActiveRecord::Base.configurations[Rails.env]
        shard_configs = config["shards"]
        shard_configs.merge!(config["seq"]) if config["seq"]
        if shard_configs
          shard_configs.each do |_name, config|
            next unless config["database"]
            ActiveRecord::Tasks::DatabaseTasks.purge config
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end
  end
end

%w(
  create:all
  create
  drop:all
  drop
  schema:dump
  schema:load
  structure:dump
  structure:load
  test:purge
).each do |task_name|
  db_namespace[task_name].enhance do
    turntable_namespace[task_name].invoke
  end
end
