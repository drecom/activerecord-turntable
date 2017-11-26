require "spec_helper"

describe ActiveRecord::Turntable::Migration do
  describe ".target_shards" do
    subject { migration_class.new.target_shards }

    context "With clusters definitions" do
      let(:migration_class) {
        Class.new(ActiveRecord::Migration[5.0]) {
          clusters :user_cluster
        }
      }
      let(:cluster) { ActiveRecord::Base.turntable_configuration.cluster(:user_cluster) }

      it { is_expected.to eq(cluster.shards) }
    end

    context "With shards definitions" do
      let(:migration_class) {
        Class.new(ActiveRecord::Migration[5.0]) {
          shards :user_shard_01
        }
      }

      it { is_expected.to eq([:user_shard_01]) }
    end
  end
end
