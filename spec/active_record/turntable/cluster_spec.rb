require "spec_helper"

describe ActiveRecord::Turntable::Cluster do
  let(:cluster_config) { ActiveRecord::Base.turntable_config[:clusters][:user_cluster] }
  let(:cluster) { ActiveRecord::Turntable::Cluster.new(cluster_config) }
  let(:mysql_mod_cluster_config) { ActiveRecord::Base.turntable_config[:clusters][:mysql_mod_cluster] }
  let(:mysql_mod_cluster) { ActiveRecord::Turntable::Cluster.new(mysql_mod_cluster_config) }
  let(:in_range_shard_key_value) { cluster_config[:shards].last[:less_than] - 1 }
  let(:out_of_range_shard_key_value) { cluster_config[:shards].last[:less_than] }

  context "When initialized" do
    subject { cluster }

    its(:shards) { should have(3).items }
  end

  context "When initialized mysql sequencer type cluster" do
    subject { mysql_mod_cluster }

    its(:shards) { should have(2).items }
    its(:seq)    { is_expected.not_to be nil }
  end

  describe "#shard_for" do
    subject { cluster.shard_for(value) }

    context "with argument in shard range value" do
      let(:value) { in_range_shard_key_value }
      let(:expected_shard_name) { cluster_config[:shards].last[:connection] }

      it { is_expected.to be_instance_of(ActiveRecord::Turntable::Shard) }
      its(:name) { is_expected.to eq expected_shard_name }
    end

    context "with argument out of shard range value" do
      let(:value) { out_of_range_shard_key_value }
      it { expect { subject }.to raise_error(ActiveRecord::Turntable::CannotSpecifyShardError) }
    end
  end
end
