# -*- coding: utf-8 -*-
#
# 採番
#

module ActiveRecord::Turntable
  class Sequencer
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :Api
      autoload :Mysql
      autoload :Barrage
    end

    @@sequence_types = {
      :api => Api,
      :mysql => Mysql,
      :barrage => Barrage
    }

    @@sequences = {}
    @@tables = {}
    cattr_reader :sequences, :tables

    def self.build(klass, sequence_name = nil, cluster_name = nil)
      sequence_name ||= current_cluster_config_for(cluster_name || klass)["seq"].keys.first
      seq_config = current_cluster_config_for(cluster_name || klass)["seq"][sequence_name]
      seq_type = (seq_config["seq_type"] ? seq_config["seq_type"].to_sym : :mysql)
      @@tables[klass.table_name] ||= (@@sequences[sequence_name(klass.table_name, klass.primary_key)] ||= @@sequence_types[seq_type].new(klass, seq_config))
    end

    def self.has_sequencer?(table_name)
      !!@@tables[table_name]
    end

    def self.sequence_name(table_name, pk)
      "#{table_name}_#{pk || 'id'}_seq"
    end

    def self.table_name(seq_name)
      seq_name.split('_').first
    end

    def next_sequence_value
      raise NotImplementedError
    end

    def current_sequence_value
      raise NotImplementedError
    end

    private

    def self.current_cluster_config_for(klass_or_name)
      cluster_name = if klass_or_name.is_a?(Symbol)
                       klass_or_name
                     else
                       klass_or_name.turntable_cluster_name.to_s
                     end
      ActiveRecord::Base.turntable_config["clusters"][cluster_name]
    end
  end
end
