module ActiveRecord::Turntable::Migration
  extend ActiveSupport::Concern

  included do
    extend ShardDefinition
    prepend OverrideMethods
    class_attribute :target_shards, :current_shard
    ::ActiveRecord::ConnectionAdapters::AbstractAdapter.include(SchemaStatementsExt)
    ::ActiveRecord::Migration::CommandRecorder.include(CommandRecorder)
    ::ActiveRecord::Migrator.prepend(Migrator)
  end

  module ShardDefinition
    def clusters(*cluster_names)
      config = ActiveRecord::Base.turntable_configuration
      (self.target_shards ||= []).concat(
        if cluster_names.first == :all
          config[:clusters].map do |_name, cluster_conf|
            cluster_conf[:shards].map { |shard| shard[:connection] }
          end
        else
          cluster_names.map do |cluster_name|
            config[:clusters][cluster_name][:shards].map do |shard|
              shard[:connection]
            end
          end.flatten
        end
      )
    end

    def shards(*connection_names)
      (self.target_shards ||= []).concat connection_names
    end
  end

  module OverrideMethods
    def announce(message)
      super("#{message} - Shard: #{current_shard}")
    end

    def exec_migration(*args)
      super(*args) if target_shard?(current_shard)
    end

    def target_shard?(shard_name)
      target_shards.blank? or target_shards.include?(shard_name)
    end
  end

  module SchemaStatementsExt
    def create_sequence_for(table_name, options = {})
      options = options.merge(id: false)

      # TODO: pkname should be pulled from table definitions
      sequence_table_name = ActiveRecord::Turntable::Sequencer.sequence_name(table_name, "id")
      create_table(sequence_table_name, options) do |t|
        t.integer :id, limit: 8
      end
      execute "INSERT INTO #{quote_table_name(sequence_table_name)} (`id`) VALUES (0)"
    end

    def drop_sequence_for(table_name, options = {})
      # TODO: pkname should be pulled from table definitions
      sequence_table_name = ActiveRecord::Turntable::Sequencer.sequence_name(table_name, "id")
      drop_table(sequence_table_name)
    end

    def rename_sequence_for(table_name, new_name)
      # TODO: pkname should pulled from table definitions
      seq_table_name = ActiveRecord::Turntable::Sequencer.sequence_name(table_name, "id")
      new_seq_name = ActiveRecord::Turntable::Sequencer.sequence_name(new_name, "id")
      rename_table(seq_table_name, new_seq_name)
    end
  end

  module CommandRecorder
    def create_sequence_for(*args)
      record(:create_sequence_for, args)
    end

    def rename_sequence_for(*args)
      record(:rename_sequence_for, args)
    end

    private

      def invert_create_sequence_for(args)
        [:drop_sequence_for, args]
      end

      def invert_rename_sequence_for(args)
        [:rename_sequence_for, args.reverse]
      end
  end

  module Migrator
    extend ActiveSupport::Concern

    def self.prepended(base)
      class << base
        prepend ClassMethods
      end
    end

    module ClassMethods
      def up(migrations_paths, target_version = nil)
        result = super

        ActiveRecord::Tasks::DatabaseTasks.each_current_turntable_cluster_connected(current_environment) do |name, configuration|
          puts "[turntable] *** Migrating database: #{configuration['database']}(Shard: #{name})"
          super(migrations_paths, target_version)
        end
        result
      end

      def down(migrations_paths, target_version = nil, &block)
        result = super

        ActiveRecord::Tasks::DatabaseTasks.each_current_turntable_cluster_connected(current_environment) do |name, configuration|
          puts "[turntable] *** Migrating database: #{configuration['database']}(Shard: #{name})"
          super(migrations_paths, target_version, &block)
        end
        result
      end

      def run(*args)
        result = super

        ActiveRecord::Tasks::DatabaseTasks.each_current_turntable_cluster_connected(current_environment) do |name, configuration|
          puts "[turntable] *** Migrating database: #{configuration['database']}(Shard: #{name})"
          super(*args)
        end
        result
      end
    end
  end
end
