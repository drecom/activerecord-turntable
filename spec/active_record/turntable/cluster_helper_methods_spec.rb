require "spec_helper"

describe ActiveRecord::Turntable::ClusterHelperMethods do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../config/turntable.yml"))
  end

  before do
    establish_connection_to(:test)
    truncate_shard
  end
  let(:clusters) { ActiveRecord::Base.turntable_clusters }

  describe ".all_cluster_transaction" do
    let(:all_clusters) { clusters.values }
    let(:shards) { all_clusters.flat_map { |c| c.shards.values } }

    it "all shards should begin transaction" do
      User.all_cluster_transaction {
        expect(shards.map(&:connection).map(&:open_transactions)).to all(be == 1)
      }
    end

    it "`requires_new` option should be passed to original transaction method" do
      User.all_cluster_transaction {
        User.all_cluster_transaction(requires_new: true) {
          expect(shards.map(&:connection).map(&:open_transactions)).to all(be > 1)
        }
      }
    end
  end

  describe ".cluster_transaction" do
    let(:cluster) { clusters[:user_cluster] }
    let(:shards) { cluster.shards.values }

    it "all shards in the cluster should begin transaction" do
      User.user_cluster_transaction {
        expect(shards.map(&:connection).map(&:open_transactions)).to all(be == 1)
      }
    end
  end
end
