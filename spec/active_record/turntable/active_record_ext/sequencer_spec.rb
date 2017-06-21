require "spec_helper"

describe ActiveRecord::Turntable::ActiveRecordExt::Sequencer do
  context "With sequencer enabled model" do
    subject { User }
    its(:sequence_name) { is_expected.not_to be_nil }
  end

  context "With sequencer disabled model" do
    subject { Item }
    its(:sequence_name) { is_expected.to be_nil }
  end
end
