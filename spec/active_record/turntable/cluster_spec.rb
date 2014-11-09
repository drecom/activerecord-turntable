require 'spec_helper'

describe ActiveRecord::Turntable::Cluster do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../config/turntable.yml"))
  end

  before do
    establish_connection_to(:test)
    truncate_shard
  end
  let(:cluster_config) { ActiveRecord::Base.turntable_config[:clusters][:user_cluster] }
  let(:cluster) { ActiveRecord::Turntable::Cluster.new(User, cluster_config) }
  let(:in_range_shard_key_value) { cluster_config[:shards].last[:less_than] - 1 }
  let(:out_of_range_shard_key_value) { cluster_config[:shards].last[:less_than] }

  context "When initialized" do
    subject { cluster }

    its(:klass) { should == User }
    its(:shards) { should have(3).items }
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
