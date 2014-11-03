module ActiveRecord::Turntable
  class Sequencer
    class Barrage < Sequencer
      @@unique_barrage_instance = {}

      def initialize(klass, options = {})
        require 'barrage'
        @klass = klass
        @options = options["options"]
        @barrage = get_barrage_instance
      end

      def next_sequence_value(sequence_name)
        @barrage.next
      end

      def current_sequence_value(sequence_name)
        @barrage.current
      end

      private

      def get_barrage_instance
        @@unique_barrage_instance[@options] ||= ::Barrage.new(@options)
      end
    end
  end
end
