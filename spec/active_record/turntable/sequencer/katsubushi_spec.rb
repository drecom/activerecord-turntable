require "spec_helper"
require "dalli"

describe ActiveRecord::Turntable::Sequencer::Katsubushi do
  let(:sequencer) { ActiveRecord::Turntable::Sequencer::Katsubushi.new(options) }
  let(:sequence_name) { "hogefuga" }
  let(:options) { { options: { servers: [{ host: "localhost", port: 11212 }], compress: true } }.with_indifferent_access }

  describe "#next_sequence_value" do
    subject { sequencer.next_sequence_value("hogefuga") }

    context "with stub" do
      let(:sequence_value) { 5_956_206_959_005_697 }

      before do
        allow_any_instance_of(Dalli::Client).to receive(:get).and_return(sequence_value)
      end

      it { is_expected.to eq(sequence_value) }
    end

    context "with real katsubushi server", with_katsubushi: true do
      it { is_expected.to be_kind_of(Integer) }
    end
  end

  describe "#current_sequence_value" do
    subject { sequencer.current_sequence_value("hogefuga") }

    context "with stub" do
      let(:sequence_value) { 5_956_206_959_005_697 }

      before do
        allow_any_instance_of(Dalli::Client).to receive(:get).and_return(sequence_value)
      end

      it { is_expected.to eq(sequence_value) }
    end

    context "with real katsubushi server", with_katsubushi: true do
      it { is_expected.to be_kind_of(Integer) }
    end
  end
end
