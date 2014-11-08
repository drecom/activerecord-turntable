require 'spec_helper'

describe ActiveRecord::Turntable::Shard do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../config/turntable.yml"))
  end

  context "When initialized" do
    before do
      establish_connection_to(:test)
      truncate_shard
    end

    subject {
      ActiveRecord::Turntable::Shard.new(ActiveRecord::Base.turntable_config[:clusters][:user_cluster][:shards][0])
    }
    its(:name) { should == ActiveRecord::Base.turntable_config[:clusters][:user_cluster][:shards][0][:connection] }
    its(:connection) { should be_instance_of(ActiveRecord::ConnectionAdapters::Mysql2Adapter) }
    its(:connection_pool) { should be_instance_of(ActiveRecord::ConnectionAdapters::ConnectionPool) }
  end
end
