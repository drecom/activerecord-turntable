# -*- coding: utf-8 -*-
#
# 採番
#

module ActiveRecord::Turntable
  class Sequencer
    autoload :Api, "active_record/turntable/sequencer/api"
    autoload :Mysql, "active_record/turntable/sequencer/mysql"
    @@sequence_types = {
      :api => Api,
      :mysql => Mysql
    }

    @@sequences = {}
    @@tables = {}
    cattr_reader :sequences, :tables

    def self.build(klass, sequence_name = nil)
      unless sequence_name
        sequence_name = ActiveRecord::Base.turntable_config["clusters"][klass.turntable_cluster_name.to_s]["seq"]["connection"]
      end
      seq_config = ActiveRecord::Base.configurations[Rails.env]["seq"][sequence_name.to_s]
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
      raise ActiveRecord::Turntable::NotImplementedError
    end

    def current_sequence_value
      raise ActiveRecord::Turntable::NotImplementedError
    end
  end
end
