# -*- coding: utf-8 -*-
#
# 採番
#

module ActiveRecord::Turntable
  class Sequencer
    class Mysql < Sequencer
      def initialize(options = {})
        @options = options
        @shard = SeqShard.new(@options[:connection].to_s)
      end

      def connection
        @shard.connection
      end

      def release!
        @shard.connection_pool.clear_all_connections!
      end

      def next_sequence_value(sequence_name)
        conn = connection
        conn.execute "UPDATE #{conn.quote_table_name(sequence_name)} SET id=LAST_INSERT_ID(id+1)"
        res = conn.execute("SELECT LAST_INSERT_ID()")
        new_id = res.first.first.to_i
        raise SequenceNotFoundError if new_id.zero?
        new_id
      end

      def current_sequence_value(sequence_name)
        conn = connection
        conn.execute "UPDATE #{conn.quote_table_name(sequence_name)} SET id=LAST_INSERT_ID(id)"
        res = conn.execute("SELECT LAST_INSERT_ID()")
        current_id = res.first.first.to_i
        current_id
      end
    end
  end
end
