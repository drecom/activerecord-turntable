require "bundler/gem_tasks"
require "rubygems"

require "rspec/core"
require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList["spec/**/*_spec.rb"]
end

require "active_record"
require "active_record/turntable/active_record_ext/database_tasks"

namespace :turntable do
  namespace :db do
    task :rails_env do
      unless defined? RAILS_ENV
        RAILS_ENV = ENV["RAILS_ENV"] ||= "test"
      end
    end

    task :load_config => :rails_env do
      yaml_file = File.join(File.dirname(__FILE__), "spec/config/database.yml")
      ActiveRecord::Base.configurations = YAML.load ERB.new(IO.read(yaml_file)).result
    end

    desc "create turntable test database"
    task :create => :load_config do
      ActiveRecord::Tasks::DatabaseTasks.create_current(RAILS_ENV)
      ActiveRecord::Tasks::DatabaseTasks.create_current_turntable_cluster(RAILS_ENV)
    end

    desc "drop turntable test database"
    task :drop => :load_config do
      ActiveRecord::Tasks::DatabaseTasks.drop_current(RAILS_ENV)
      ActiveRecord::Tasks::DatabaseTasks.drop_current_turntable_cluster(RAILS_ENV)
    end

    desc "migrate turntable test tables"
    task :migrate => :load_config do
      ActiveRecord::Base.establish_connection RAILS_ENV.to_sym
      require "active_record/turntable"
      ActiveRecord::Base.include(ActiveRecord::Turntable)
      ActiveRecord::ConnectionAdapters::SchemaStatements.include(ActiveRecord::Turntable::Migration::SchemaStatementsExt)

      configurations = [ActiveRecord::Base.configurations[RAILS_ENV]]
      configurations += ActiveRecord::Tasks::DatabaseTasks.current_turntable_cluster_configurations(RAILS_ENV).map { |v| v[1] }.flatten.uniq

      configurations.each do |configuration|
        ActiveRecord::Base.establish_connection configuration

        ActiveRecord::Base.connection.create_table :users do |t|
          t.string :nickname
          t.string :thumbnail_url
          t.binary :blob
          t.datetime :joined_at
          t.datetime :deleted_at
          t.timestamps
        end
        ActiveRecord::Base.connection.create_sequence_for :users

        ActiveRecord::Base.connection.create_table :user_statuses do |t|
          t.belongs_to :user, :null => false
          t.integer    :hp,   :null => false, :default => 0
          t.integer    :mp,   :null => false, :default => 0
          t.integer    :lock_version, :null => false, :default => 0
          t.datetime   :deleted_at, :default => nil
          t.timestamps
        end
        ActiveRecord::Base.connection.create_sequence_for :user_statuses

        ActiveRecord::Base.connection.create_table :cards do |t|
          t.string :name, :null => false
          t.integer :hp,  :null => false, :default => 0
          t.integer :mp,  :null => false, :default => 0
          t.timestamps
        end
        ActiveRecord::Base.connection.create_table :archived_cards do |t|
          t.string :name, :null => false
          t.integer :hp,  :null => false, :default => 0
          t.integer :mp,  :null => false, :default => 0
          t.timestamps
          t.datetime :deleted_at, :default => nil
        end

        ActiveRecord::Base.connection.create_table :cards_users do |t|
          t.belongs_to :card,    :null => false
          t.belongs_to :user,    :null => false
          t.integer    :num,     :default => 1, :null => false
          t.timestamps
        end
        ActiveRecord::Base.connection.create_sequence_for :cards_users

        ActiveRecord::Base.connection.create_table :archived_cards_users do |t|
          t.belongs_to :card,    :null => false
          t.belongs_to :user,    :null => false
          t.timestamps
          t.datetime   :deleted_at, :default => nil
        end
        ActiveRecord::Base.connection.create_sequence_for :archived_cards_users

        ActiveRecord::Base.connection.create_table :cards_users_histories do |t|
          t.belongs_to :cards_user,    :null => false
          t.belongs_to :user, :null => false
          t.timestamps
        end
        ActiveRecord::Base.connection.create_sequence_for :cards_users_histories

        ActiveRecord::Base.connection.create_table :events_users_histories do |t|
          t.belongs_to :events_user, :null => false
          t.belongs_to :cards_user,    :null => false
          t.belongs_to :user, :null => false
          t.timestamps
        end
        ActiveRecord::Base.connection.create_sequence_for :events_users_histories
      end
    end

    desc "drop turntable test database"
    task :drop => :load_config do
      ActiveRecord::Tasks::DatabaseTasks.drop_current_turntable_cluster(RAILS_ENV)
    end

    desc "reset turntable test databases"
    task :reset => ["turntable:db:drop", "turntable:db:create", "turntable:db:migrate"]
  end
end
