require 'spec_helper'

describe "transaction" do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../config/turntable.yml"))
  end

  before(:each) do
    establish_connection_to(:test)
    truncate_shard
  end
  let(:clusters) { ActiveRecord::Base.turntable_clusters }

  describe "all_cluster_transaction" do
    let(:all_clusters) { clusters.values.map { |v| v.values.first } }
    let(:shards) { all_clusters.map { |c| c.shards.values }.flatten(1) }

    it "all shards should begin transaction" do
      User.all_cluster_transaction {
        expect(shards.map(&:connection).map(&:open_transactions)).to all(be == 1)
      }
    end
  end

  describe "cluster_transaction" do
    let(:cluster) { clusters[:user_cluster].values.first }
    let(:shards) { cluster.shards.values }

    it "all shards in the cluster should begin transaction" do
      User.user_cluster_transaction {
        expect(shards.map(&:connection).map(&:open_transactions)).to all(be == 1)
      }
    end
  end
end
