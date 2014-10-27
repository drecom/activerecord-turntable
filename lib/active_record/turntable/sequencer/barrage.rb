module ActiveRecord::Turntable
  class Sequencer
    class Barrage < Sequencer
      def initialize(klass, options = {})
        require 'barrage'
        @klass = klass
        @options = options["options"]
        @barrage = ::Barrage.new(@options)
      end

      def next_sequence_value(sequence_name)
        @barrage.next
      end

      def current_sequence_value(sequence_name)
        @barrage.current
      end
    end
  end
end
