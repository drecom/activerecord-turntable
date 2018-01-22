module ActiveRecord::Turntable
  class Sequencer
    class Katsubushi < Sequencer
      def initialize(options = {})
        @options = options["options"]

        opts = @options.dup
        servers = opts.delete("servers").map do |server|
          "#{server["host"]}:#{server["port"]}"
        end

        require "dalli"
        dalli_opts = opts.with_indifferent_access
        @client = Dalli::Client.new(servers, dalli_opts)
      end

      def next_sequence_value(sequence_name)
        @client.get(sequence_name || "id").to_i
      end

      def current_sequence_value(sequence_name)
        next_sequence_value(sequence_name)
      end
    end
  end
end
