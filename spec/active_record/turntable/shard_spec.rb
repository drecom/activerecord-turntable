require "spec_helper"

describe ActiveRecord::Turntable::Shard do
  let(:cluster) { ActiveRecord::Turntable::Cluster.new }

  context "When initialized" do
    subject { ActiveRecord::Turntable::Shard.new(cluster, "user_shard_1") }


    its(:name) { is_expected.to eq("user_shard_1") }
    its(:connection) { is_expected.to be_instance_of(ActiveRecord::ConnectionAdapters::Mysql2Adapter) }
    its(:connection_pool) { is_expected.to be_instance_of(ActiveRecord::ConnectionAdapters::ConnectionPool) }
  end

  context "#connection" do
    subject { shard.connection }
    let(:shard) { ActiveRecord::Turntable::Shard.new(cluster, "user_shard_1") }

    its(:turntable_shard_name) { is_expected.to eq(shard.name) }
  end
end
