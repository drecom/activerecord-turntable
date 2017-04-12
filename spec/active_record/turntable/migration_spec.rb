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
      let(:cluster_config) { ActiveRecord::Base.turntable_config[:clusters][:user_cluster] }
      let(:user_cluster_shards) { cluster_config[:shards].map { |s| s[:connection] } }

      it { is_expected.to eq(user_cluster_shards) }
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
