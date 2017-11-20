require "spec_helper"

describe ActiveRecord::Turntable::Cluster do
  let(:cluster) { ActiveRecord::Base.turntable_configuration.cluster(:user_cluster) }
  let(:mysql_mod_cluster) { ActiveRecord::Base.turntable_configuration.cluster(:mysql_mod_cluster) }
  let(:in_range_shard_key_value) { cluster.shard_maps.last.range.max }
  let(:out_of_range_shard_key_value) { cluster.shard_maps.last.range.max + 1 }

  context "When initialized" do
    subject { cluster }

    its(:shards) { should have(3).items }
    its(:shard_maps) { should have(5).items }
  end

  context "When initialized mysql sequencer type cluster" do
    subject { mysql_mod_cluster }

    its(:shards) { should have(3).items }
    its(:shard_maps) { should have(3).items }

    context "#sequencer" do
      subject { mysql_mod_cluster.sequencer(sequencer_name) }

      context "with valid name" do
        let(:sequencer_name) { "user_seq" }

        it { is_expected.not_to be nil }
      end

      context "with invalid name" do
        let(:sequencer_name) { "invalid_sequencer_name" }

        it { is_expected.to be nil }
      end
    end
  end

  describe "#shard_for" do
    subject { cluster.shard_for(value) }

    context "with argument in shard range value" do
      let(:value) { in_range_shard_key_value }
      let(:expected_shard_name) { cluster.shards.last.name }

      it { is_expected.to be_instance_of(ActiveRecord::Turntable::Shard) }
      its(:name) { is_expected.to eq expected_shard_name }
    end

    context "with argument out of shard range value" do
      let(:value) { out_of_range_shard_key_value }

      it { expect { subject }.to raise_error(ActiveRecord::Turntable::CannotSpecifyShardError) }
    end
  end
end
