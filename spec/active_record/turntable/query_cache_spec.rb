require "spec_helper"
require "active_support/executor"

describe ActiveRecord::Turntable::QueryCache do
  subject { mw.call({}) }
  let(:mw) {
    executor = Class.new(ActiveSupport::Executor)
    ActiveRecord::Turntable::QueryCache.install_executor_hooks executor
    ->(_env) {
      executor.wrap {
        [200, {}, nil]
      }
    }
  }

  it "returns 200 response" do
    expect(subject.first).to eq(200)
  end
end
