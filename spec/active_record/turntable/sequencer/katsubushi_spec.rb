require "spec_helper"

describe ActiveRecord::Turntable::Sequencer::Katsubushi do
  let(:sequencer) { ActiveRecord::Turntable::Sequencer::Katsubushi.new(options) }
  let(:sequence_name) { "hogefuga" }
  let(:options) { { options: { servers: [{ host: "localhost", port: 11212 }], compress: true } }.with_indifferent_access }

  describe "#next_sequence_value" do
    subject { sequencer.next_sequence_value("hogefuga") }

    it { is_expected.to be_kind_of(Integer) }
  end

  describe "#current_sequence_value" do
    subject { sequencer.current_sequence_value("hogefuga") }

    it { is_expected.to be_kind_of(Integer) }
  end
end
