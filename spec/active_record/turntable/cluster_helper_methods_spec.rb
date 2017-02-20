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

  describe ".weighted_random_shard_with" do
    let(:cluster) { clusters[:user_cluster] }
    let(:shards) { cluster.shards.values }

    context "When checking `shard_fixed?` from given block" do
      subject { User.weighted_random_shard_with(&block) }
      let(:block) { -> { User.connection.shard_fixed? } }
      it { is_expected.to be true }
    end

    # OPTIMIZE: slow spec that iterates 1000 times to check probablities
    context "When checking current target shard from given block" do
      subject do
        result_array = Array.new(shard_size, 0)

        try_count.times do
          shard = User.weighted_random_shard_with { User.connection.current_shard }
          result_array[shards.index(shard)] += 1
        end

        result_array.map { |v| v / try_count.to_f }
      end

      let(:try_count) { 1000 }
      let(:weighted_shards) do
        Hash[shards.map.with_index do |shard, idx|
          [shard, shard_users_counts[idx]]
        end]
      end
      let(:shard_size) { 3 }
      let(:shard_users_counts) do
        shard_size.times.map { |idx| users_in_each_shard[idx] }
      end
      let(:all_users_count) { shard_users_counts.sum }

      where(:users_in_each_shard, :probabilities_in_each_shard) do
        [
          [[10, 10, 10], [0.333, 0.333, 0.333]],
          [[1,  8,  1], [0.1, 0.8, 0.1]],
          [[10, 0,  10], [0.5, 0, 0.5]],
        ]
      end

      with_them do
        it do
          allow(cluster).to receive(:weighted_shards).and_return(weighted_shards)
          result = subject
          probabilities_matcher = shard_size.times.map do |idx|
            be_within(0.05).of(probabilities_in_each_shard[idx])
          end
          expect(result).to match_array(probabilities_matcher)
        end
      end
    end
  end
end
