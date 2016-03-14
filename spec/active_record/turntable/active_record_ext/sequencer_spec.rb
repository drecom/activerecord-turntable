require 'spec_helper'

describe ActiveRecord::Turntable::ActiveRecordExt::Sequencer do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../../config/turntable.yml"))
  end

  before(:each) do
    establish_connection_to(:test)
    truncate_shard
  end

  context "With sequencer enabled model" do
    subject { User }
    its(:sequence_name) { is_expected.to_not be_nil }
  end

  context "With sequencer disabled model" do
    subject { Card }
    its(:sequence_name) { is_expected.to be_nil }
  end
end
