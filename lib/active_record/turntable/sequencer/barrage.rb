module ActiveRecord::Turntable
  class Sequencer
    class Barrage < Sequencer
      class_attribute :unique_barrage_instance
      self.unique_barrage_instance = {}

      def initialize(options = {})
        require "barrage"
        @options = options["options"]
      end

      def next_sequence_value(sequence_name)
        barrage.next
      end

      def current_sequence_value(sequence_name)
        barrage.current
      end

      private

        def barrage
          self.unique_barrage_instance[@options] ||= ::Barrage.new(@options)
        end
    end
  end
end
