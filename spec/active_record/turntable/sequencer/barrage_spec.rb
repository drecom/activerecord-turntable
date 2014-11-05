require 'spec_helper'

describe ActiveRecord::Turntable::Sequencer::Barrage do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../../config/turntable.yml"))
  end

  let(:sequencer) { ActiveRecord::Turntable::Sequencer::Barrage.new(klass, options) }
  let(:sequence_name) { "hogefuga" }
  let(:options) { { "options" => { "generators" => [ {"name" => "sequence", "length" => 16} ] } } }
  let(:klass) { Class.new }

  describe "#next_sequence_value" do
    subject { sequencer.next_sequence_value("hogefuga") }
    it { is_expected.to be_kind_of(Integer) }
  end

  describe "#current_sequence_value" do
    subject { sequencer.current_sequence_value("hogefuga") }
    it { is_expected.to be_kind_of(Integer) }
  end
end
