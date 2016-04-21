require "spec_helper"

describe ActiveRecord::Turntable::Sequencer::Mysql do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../../config/turntable.yml"))
  end

  let(:sequencer) { ActiveRecord::Turntable::Sequencer::Mysql.new(klass, options) }
  let(:sequence_name) { "users_id_seq" }
  let(:options) { {} }
  let(:klass) { User }

  describe "#next_sequence_value" do
    subject { sequencer.next_sequence_value(sequence_name) }
    it { is_expected.to be_kind_of(Integer) }
  end

  describe "#current_sequence_value" do
    subject { sequencer.current_sequence_value(sequence_name) }
    it { is_expected.to be_kind_of(Integer) }
  end
end
