require "spec_helper"
require "active_support/executor"

describe ActiveRecord::Turntable::QueryCache do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../config/turntable.yml"))
  end

  before do
    establish_connection_to(:test)
    truncate_shard
  end

  let(:mw) {
    executor = Class.new(ActiveSupport::Executor)
    ActiveRecord::Turntable::QueryCache.install_executor_hooks executor
    ->(_env) {
      executor.wrap {
        [200, {}, nil]
      }
    }
  }
  subject { mw.call({}) }

  it "returns 200 response" do
    expect(subject.first).to eq(200)
  end
end
