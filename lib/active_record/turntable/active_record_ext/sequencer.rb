module ActiveRecord::Turntable::ActiveRecordExt
  module Sequencer
    def next_sequence_value
      return super unless sequencer_enabled?

      turntable_sequencer.next_sequence_value(sequence_name)
    end

    def reset_sequence_name
      return super unless sequencer_enabled?

      turntable_sequencer.sequence_name(table_name, primary_key)
    end

    def prefetch_primary_key?
      sequencer_enabled? || super
    end

    def current_sequence_value(sequence_name)
      turntable_sequencer.current_sequence_value(sequence_name)
    end
  end
end
