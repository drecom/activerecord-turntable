module ActiveRecord::Turntable::ActiveRecordExt
  module Sequencer
    def default_sequence_name(table_name, pk = nil)
      if ActiveRecord::Turntable::Sequencer.has_sequencer?(table_name)
        ActiveRecord::Turntable::Sequencer.sequence_name(table_name, pk)
      else
        super
      end
    end

    def prefetch_primary_key?(table_name = nil)
      ActiveRecord::Turntable::Sequencer.has_sequencer?(table_name)
    end

    def next_sequence_value(sequence_name)
      ActiveRecord::Turntable::Sequencer.sequences[sequence_name].next_sequence_value(sequence_name)
    end

    def current_sequence_value(sequence_name)
      ActiveRecord::Turntable::Sequencer.sequences[sequence_name].current_sequence_value(sequence_name)
    end
  end
end
