require 'spec_helper'

describe ActiveRecord::Turntable::Rack::QueryCache do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../../config/turntable.yml"))
  end

  before do
    establish_connection_to(:test)
    truncate_shard
  end

  let(:mw) { ActiveRecord::Turntable::Rack::QueryCache.new lambda {|env| [200, {}]} }
  subject { mw.call({}) }

  it "should returns 200 response" do
    expect(subject.first).to eq(200)
  end
end
