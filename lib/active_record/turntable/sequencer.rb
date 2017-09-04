module ActiveRecord::Turntable
  class Sequencer
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :Api
      autoload :Mysql
      autoload :Barrage
    end

    def sequence_name(table_name, primary_key = 'id')
      [table_name, primary_key, "seq"].join("_")
    end

    def release!
      # Release subclasses if necessary
    end

    class << self
      def class_for(name_or_class)
        case name_or_class
        when Sequencer
          name_or_class
        else
          const_get("#{name_or_class.to_s.classify}")
        end
      end

      def sequence_name(table_name, primary_key = 'id')
        [table_name, primary_key, "seq"].join("_")
      end
    end

    def next_sequence_value(sequence_name)
      raise NotImplementedError
    end

    def current_sequence_value(sequence_name)
      raise NotImplementedError
    end
  end
end
