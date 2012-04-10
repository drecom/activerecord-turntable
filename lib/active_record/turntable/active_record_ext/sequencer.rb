module ActiveRecord::Turntable::ActiveRecordExt
  module Sequencer
    extend ActiveSupport::Concern

    included do
      include DatabaseStatements
      alias_method_chain :prefetch_primary_key?, :turntable
    end

    module DatabaseStatements
      def default_sequence_name(table_name, pk = nil)
        ActiveRecord::Turntable::Sequencer.sequence_name(table_name, pk)
      end
    end

    def prefetch_primary_key_with_turntable?(table_name = nil)
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
