require "spec_helper"

describe ActiveRecord::Turntable::Sequencer::Barrage do
  let(:sequencer) { ActiveRecord::Turntable::Sequencer::Barrage.new(options) }
  let(:sequence_name) { "hogefuga" }
  let(:options) { { options: { generators: [{ name: "sequence", length: 16 }] } }.with_indifferent_access }

  describe "#next_sequence_value" do
    subject { sequencer.next_sequence_value("hogefuga") }
    it { is_expected.to be_kind_of(Integer) }
  end

  describe "#current_sequence_value" do
    subject { sequencer.current_sequence_value("hogefuga") }
    it { is_expected.to be_kind_of(Integer) }
  end
end
