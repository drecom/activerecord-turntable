# -*- coding: utf-8 -*-
#
# Sequencer via HTTP API
#
require "httpclient"

module ActiveRecord::Turntable
  class Sequencer
    class Api < Sequencer
      API_ENDPOINT = "/sequences/".freeze
      NEXT_VALUE_ENDPOINT = "/new".freeze

      def initialize(klass, options = {})
        @klass = klass
        @options = options
        @host = @options[:api_host]
        @port = @options[:api_port]
        @client = HTTPClient.new
      end

      def next_sequence_value(sequence_name)
        res = @client.get_content("http://#{@host}:#{@port}#{API_ENDPOINT}#{sequence_name}#{NEXT_VALUE_ENDPOINT}")
        new_id = res.to_i
        raise SequenceNotFoundError if new_id.zero?
        new_id
      end

      def current_sequence_value(sequence_name)
        res = @client.get_content("http://#{@host}:#{@port}#{API_ENDPOINT}#{sequence_name}")
        current_id = res.to_i
        raise SequenceNotFoundError if current_id.zero?
        current_id
      end
    end
  end
end
