require "spec_helper"

describe ActiveRecord::Turntable::ActiveRecordExt::LogSubscriber do
  class TestLogSubscriber < ActiveRecord::LogSubscriber
    attr_reader :debugs

    def initialize
      @debugs = []
      super
    end

    def debug(message)
      @debugs << message
    end
  end

  TestEvent = Struct.new(:payload) do
    def sql
      "foo"
    end

    def duration
      0
    end
  end

  describe "#sql" do
    it "ignore SCHEMA log" do
      subscriber = TestLogSubscriber.new
      expect(subscriber.debugs.length).to eq 0

      subscriber.sql(TestEvent.new(name: "bar", turntable_shard_name: "shard_1"))
      expect(subscriber.debugs.length).to eq 1

      subscriber.sql(TestEvent.new(name: "SCHEMA", turntable_shard_name: "shard_1"))
      expect(subscriber.debugs.length).to eq 1
    end
  end
end
