require "spec_helper"

describe ActiveRecord::Turntable::Shard do
  context "When initialized" do
    subject {
      ActiveRecord::Turntable::Shard.new(ActiveRecord::Base.turntable_config[:clusters][:user_cluster][:shards][0])
    }
    its(:name) { should == ActiveRecord::Base.turntable_config[:clusters][:user_cluster][:shards][0][:connection] }
    its(:connection) { should be_instance_of(ActiveRecord::ConnectionAdapters::Mysql2Adapter) }
    its(:connection_pool) { should be_instance_of(ActiveRecord::ConnectionAdapters::ConnectionPool) }
  end

  context "#connection" do
    subject { shard.connection }
    let(:shard) do
      ActiveRecord::Turntable::Shard.new(ActiveRecord::Base.turntable_config[:clusters][:user_cluster][:shards][0])
    end
    its(:turntable_shard_name) { is_expected.to eq(shard.name) }
  end
end
