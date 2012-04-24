require "bundler/gem_tasks"
require 'rubygems'

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

namespace :turntable do
  namespace :db do
    task :rails_env do
      unless defined? RAILS_ENV
        RAILS_ENV = ENV['RAILS_ENV'] ||= 'test'
      end
    end

    task :load_config => :rails_env do
      require 'active_record'
      ActiveRecord::Base.configurations = YAML.load_file(File.join(File.dirname(__FILE__), 'spec/config/database.yml'))
    end

    desc "create turntable test database"
    task :create => :load_config do
      database_configs = [ActiveRecord::Base.configurations[RAILS_ENV]] + ActiveRecord::Base.configurations[RAILS_ENV]["shards"].values + ActiveRecord::Base.configurations[RAILS_ENV]["seq"].values
      database_configs.each do |dbconf|
        command = "mysql "
        command << "-u #{dbconf["username"]} " if dbconf["username"]
        command << "-p#{dbconf["password"]} " if dbconf["password"]
        command << "-h #{dbconf["host"]}" if dbconf["host"]
        %x{ echo "CREATE DATABASE #{dbconf["database"]}" | #{command} }
      end
    end

    desc "migrate turntable test tables"
    task :migrate => :load_config do
      ActiveRecord::Base.establish_connection RAILS_ENV
      require 'active_record/turntable'
      ActiveRecord::Base.send(:include, ActiveRecord::Turntable)
      ActiveRecord::ConnectionAdapters::SchemaStatements.send(:include, ActiveRecord::Turntable::Migration::SchemaStatementsExt)
      database_configs = [ActiveRecord::Base.configurations[RAILS_ENV]] + ActiveRecord::Base.configurations[RAILS_ENV]["shards"].values + ActiveRecord::Base.configurations[RAILS_ENV]["seq"].values

      database_configs.each do |dbconf|
        ActiveRecord::Base.establish_connection dbconf

        ActiveRecord::Base.connection.create_table :users do |t|
          t.string :nickname
          t.string :thumbnail_url
          t.datetime :joined_at
          t.datetime :deleted_at
          t.timestamps
        end
        ActiveRecord::Base.connection.create_sequence_for :users

        ActiveRecord::Base.connection.create_table :user_statuses do |t|
          t.belongs_to :user, :null => false
          t.integer    :hp,   :null => false, :default => 0
          t.integer    :mp,   :null => false, :default => 0
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
      end
    end

    desc "drop turntable test database"
    task :drop => :load_config do
      database_configs = [ActiveRecord::Base.configurations[RAILS_ENV]] + ActiveRecord::Base.configurations[RAILS_ENV]["shards"].values + ActiveRecord::Base.configurations[RAILS_ENV]["seq"].values
      database_configs.each do |dbconf|
        command = "mysql "
        command << "-u #{dbconf["username"]} " if dbconf["username"]
        command << "-p#{dbconf["password"]} " if dbconf["password"]
        command << "-h #{dbconf["host"]}" if dbconf["host"]
        %x{ echo "DROP DATABASE #{dbconf["database"]}" | #{command} }
      end
    end

    task :reset => ["turntable:db:drop", "turntable:db:create", "turntable:db:migrate"]
  end
end
