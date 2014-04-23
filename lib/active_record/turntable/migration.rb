module ActiveRecord::Turntable::Migration
  extend ActiveSupport::Concern

  included do
    extend ShardDefinition
    class_attribute :target_shards
    def announce_with_turntable(message)
      announce_without_turntable("#{message} - #{get_current_shard}")
    end

    alias_method_chain :migrate, :turntable
    alias_method_chain :announce, :turntable
    ::ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, SchemaStatementsExt)
    ::ActiveRecord::Migration::CommandRecorder.send(:include, CommandRecorder)
  end

  module ShardDefinition
    def clusters(*cluster_names)
      config = ActiveRecord::Base.turntable_config
      (self.target_shards ||= []) <<
        if cluster_names.first == :all
          config['clusters'].map do |name, cluster_conf|
            cluster_conf["shards"].map {|shard| shard["connection"]}
          end
        else
          cluster_names.map do |cluster_name|
            config['clusters'][cluster_name]["shards"].map do |shard|
              shard["connection"]
            end
          end
        end
    end

    def shards(*connection_names)
      (self.target_shards ||= []) << connection_names
    end
  end

  def get_current_shard
    "Shard: #{@@current_shard}" if @@current_shard
  end

  def migrate_with_turntable(direction)
    config = ActiveRecord::Base.configurations
    @@current_shard = nil
    shards = (self.class.target_shards||=[]).flatten.uniq.compact
    if self.class.target_shards.blank?
      return migrate_without_turntable(direction)
    end

    shards_conf = shards.map do |shard|
      config[Rails.env||"development"]["shards"][shard]
    end
    seqs = config[Rails.env||"development"]["seq"]
    shards_conf += seqs.values if seqs
    shards_conf << config[Rails.env||"development"]
    shards_conf.each_with_index do |conf, idx|
      next unless conf["database"]
      @@current_shard = shards[idx] || (seqs && seqs.keys[idx - shards.size]) || "master"
      ActiveRecord::Base.establish_connection(conf)
      if !ActiveRecord::Base.connection.table_exists?(ActiveRecord::Migrator.schema_migrations_table_name())
        ActiveRecord::Base.connection.initialize_schema_migrations_table
      end
      migrate_without_turntable(direction)
    end
  end

  module SchemaStatementsExt
    def create_sequence_for(table_name, options = { })
      options = options.merge(:id => false)

      # TODO: pkname should be pulled from table definitions
      pkname = "id"
      sequence_table_name = ActiveRecord::Turntable::Sequencer.sequence_name(table_name, "id")
      create_table(sequence_table_name, options) do |t|
        t.integer :id, :limit => 8
      end
      execute "INSERT INTO #{quote_table_name(sequence_table_name)} (`id`) VALUES (0)"
    end

    def drop_sequence_for(table_name, options = { })
      # TODO: pkname should be pulled from table definitions
      pkname = "id"
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

end
