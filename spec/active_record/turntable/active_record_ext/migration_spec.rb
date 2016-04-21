require "spec_helper"

describe ActiveRecord::Turntable::Migration do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../../config/turntable.yml"))
  end

  before(:each) do
    establish_connection_to(:test)
    truncate_shard
  end

  describe ".target_shards" do
    subject { migration_class.new.target_shards }

    context "With clusters definitions" do
      let(:migration_class) {
        klass = Class.new(ActiveRecord::Migration) {
          clusters :user_cluster
        }
      }
      let(:cluster_config) { ActiveRecord::Base.turntable_config["clusters"]["user_cluster"] }
      let(:user_cluster_shards) { cluster_config["shards"].map { |s| s["connection"] } }

      it { is_expected.to eq(user_cluster_shards) }
    end

    context "With shards definitions" do
      let(:migration_class) {
        klass = Class.new(ActiveRecord::Migration) {
          shards :user_shard_01
        }
      }

      it { is_expected.to eq([:user_shard_01]) }
    end
  end
end
