require 'active_record/turntable'
ActiveRecord::SchemaDumper.send(:include, ActiveRecord::Turntable::ActiveRecordExt::SchemaDumper)

db_namespace = namespace :db do
  task :create do
    if Rails.env.development? && ActiveRecord::Base.configurations['test'] && ActiveRecord::Base.configurations["test"]["shards"]
      dbs = ActiveRecord::Base.configurations["test"]["shards"].values
      dbs += ActiveRecord::Base.configurations["test"]["seq"].values if ActiveRecord::Base.configurations["test"]["seq"]
      dbs.each do |shard_config|
        create_database(shard_config)
      end
    end
    if shard_configs = ActiveRecord::Base.configurations[Rails.env || 'development']["shards"]
      dbs = shard_configs.values
      dbs += ActiveRecord::Base.configurations[Rails.env || 'development']["seq"].values if ActiveRecord::Base.configurations[Rails.env || 'development']["seq"]
      dbs.each do |shard_config|
        create_database(shard_config)
      end
    end
    config = ActiveRecord::Base.configurations[Rails.env || 'development']
    ActiveRecord::Base.establish_connection(config)
  end

  task :drop do
    config = ActiveRecord::Base.configurations[Rails.env || 'development']
    shard_configs = config["shards"]
    if shard_configs
      dbs = shard_configs.values
      dbs += ActiveRecord::Base.configurations[Rails.env || 'development']["seq"].values if ActiveRecord::Base.configurations[Rails.env || 'development']["seq"]
      dbs.each do |shard_config|
        begin
          drop_database(shard_config)
        rescue Exception => e
          $stderr.puts "Couldn't drop #{ config['database']} : #{e.inspect}"
        end
      end
    end
    ActiveRecord::Base.establish_connection(config)
  end

  namespace :schema do
    task :dump do
      require 'active_record/schema_dumper'
      config = ActiveRecord::Base.configurations[Rails.env]
      shard_configs = config["shards"]
      shard_configs.merge!(config["seq"]) if config["seq"]
      if shard_configs
        shard_configs.each do |name, config|
          filename = ENV['SCHEMA'] || "#{Rails.root}/db/schema-#{name}.rb"
          File.open(filename, "w:utf-8") do |file|
            ActiveRecord::Base.establish_connection(config)
            ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
          end
        end
      end
      ActiveRecord::Base.establish_connection(config)
      db_namespace['schema:dump'].reenable
    end

    desc 'Load a schema.rb file into the database'
    task :load => :environment do
      config = ActiveRecord::Base.configurations[Rails.env]
      shard_configs = config["shards"]
      shard_configs.merge!(config["seq"]) if config["seq"]
      if shard_configs
        shard_configs.each do |name, config|
          ActiveRecord::Base.establish_connection(config)
          file = ENV['SCHEMA'] || "#{Rails.root}/db/schema-#{name}.rb"
          if File.exists?(file)
            load(file)
          else
            abort %{#{file} doesn't exist yet. Run "rake db:migrate" to create it then try again. If you do not intend to use a database, you should instead alter #{Rails.root}/config/application.rb to limit the frameworks that will be loaded'}
          end
        end
      end
      ActiveRecord::Base.establish_connection(config)
    end
  end

  namespace :structure do
    desc 'Dump the database structure to an SQL file'
    task :dump => :environment do
      config = ActiveRecord::Base.configurations[Rails.env]
      shard_configs = config["shards"]
      shard_configs.merge!(config["seq"]) if config["seq"]
      if shard_configs
        shard_configs.each do |name, config|
          case config['adapter']
          when /mysql/, 'oci', 'oracle'
            ActiveRecord::Base.establish_connection(config)
            File.open("#{Rails.root}/db/#{Rails.env}_#{name}_structure.sql", "w+") { |f| f << ActiveRecord::Base.connection.structure_dump }
          when /postgresql/
            ENV['PGHOST']     = config['host'] if config['host']
            ENV['PGPORT']     = config["port"].to_s if config['port']
            ENV['PGPASSWORD'] = config['password'].to_s if config['password']
            search_path = config['schema_search_path']
            unless search_path.blank?
              search_path = search_path.split(",").map{|search_path| "--schema=#{search_path.strip}" }.join(" ")
            end
            `pg_dump -i -U "#{config['username']}" -s -x -O -f db/#{Rails.env}_#{name}_structure.sql #{search_path} #{config['database']}`
            raise 'Error dumping database' if $?.exitstatus == 1
          when /sqlite/
            dbfile = config['database'] || config['dbfile']
            `sqlite3 #{dbfile} .schema > db/#{Rails.env}_#{name}_structure.sql`
          when 'sqlserver'
            `smoscript -s #{config['host']} -d #{config['database']} -u #{config['username']} -p #{config['password']} -f db\\#{Rails.env}_#{name}_structure.sql -A -U`
          when "firebird"
            set_firebird_env(config)
            db_string = firebird_db_string(config)
            sh "isql -a #{db_string} > #{Rails.root}/db/#{Rails.env}_#{name}_structure.sql"
          else
            raise "Task not supported by '#{config["adapter"]}'"
          end

          if ActiveRecord::Base.connection.supports_migrations?
            File.open("#{Rails.root}/db/#{Rails.env}_#{name}_structure.sql", "a") { |f| f << ActiveRecord::Base.connection.dump_schema_information }
          end
        end
      end
      ActiveRecord::Base.establish_connection(config)
    end
  end


  namespace :test do
    # desc "Recreate the test databases from the development structure"
    task :clone_structure do
      config = ActiveRecord::Base.configurations[Rails.env]
      shard_configs = config["shards"]
      shard_configs.merge!(config["seq"]) if config["seq"]
      if shard_configs
        shard_configs.each do |name, config|
          case config['adapter']
          when /mysql/
            ActiveRecord::Base.establish_connection(config)
            ActiveRecord::Base.connection.execute('SET foreign_key_checks = 0')
            IO.readlines("#{Rails.root}/db/#{Rails.env}_#{name}_structure.sql").join.split("\n\n").each do |table|
              ActiveRecord::Base.connection.execute(table)
            end
          when /postgresql/
            ENV['PGHOST']     = config['host'] if config['host']
            ENV['PGPORT']     = config['port'].to_s if config['port']
            ENV['PGPASSWORD'] = config['password'].to_s if config['password']
            `psql -U "#{config['username']}" -f "#{Rails.root}/db/#{Rails.env}#{name}_structure.sql" #{config['database']} #{config['template']}`
          when /sqlite/
            dbfile = config['database'] || config['dbfile']
            `sqlite3 #{dbfile} < "#{Rails.root}/db/#{Rails.env}#{name}_structure.sql"`
          when 'sqlserver'
            `sqlcmd -S #{config['host']} -d #{config['database']} -U #{config['username']} -P #{config['password']} -i db\\#{Rails.env}#{name}_structure.sql`
          when 'oci', 'oracle'
            ActiveRecord::Base.establish_connection(config)
            IO.readlines("#{Rails.root}/db/#{Rails.env}#{name}_structure.sql").join.split(";\n\n").each do |ddl|
              ActiveRecord::Base.connection.execute(ddl)
            end
          when 'firebird'
            set_firebird_env(config)
            db_string = firebird_db_string(config)
            sh "isql -i #{Rails.root}/db/#{Rails.env}#{name}_structure.sql #{db_string}"
          else
            raise "Task not supported by '#{config['adapter']}'"
          end
        end
      end
      ActiveRecord::Base.establish_connection(config)
    end

    # desc "Empty the test database"
    task :purge => :environment do
      config = ActiveRecord::Base.configurations[Rails.env]
      shard_configs = config["shards"]
      shard_configs.merge!(config["seq"]) if config["seq"]
      if shard_configs
        shard_configs.each do |name, config|
          case config['adapter']
          when /mysql/
            ActiveRecord::Base.establish_connection(config)
            ActiveRecord::Base.connection.recreate_database(config['database'], mysql_creation_options(config))
          when /postgresql/
            ActiveRecord::Base.clear_active_connections!
            drop_database(config)
            create_database(config)
          when /sqlite/
            dbfile = config['database'] || config['dbfile']
            File.delete(dbfile) if File.exist?(dbfile)
          when 'sqlserver'
            # TODO
          when "oci", "oracle"
            ActiveRecord::Base.establish_connection(config)
            ActiveRecord::Base.connection.structure_drop.split(";\n\n").each do |ddl|
              ActiveRecord::Base.connection.execute(ddl)
            end
          when 'firebird'
            ActiveRecord::Base.establish_connection(config)
            ActiveRecord::Base.connection.recreate_database!
          else
            raise "Task not supported by '#{config['adapter']}'"
          end
        end
      end
      ActiveRecord::Base.establish_connection(config)
    end
  end

end

