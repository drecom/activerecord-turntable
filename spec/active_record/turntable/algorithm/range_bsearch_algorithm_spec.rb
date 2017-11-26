require "spec_helper"

describe ActiveRecord::Turntable::Algorithm::RangeBsearchAlgorithm do
  let(:algorithm) { ActiveRecord::Turntable::Algorithm::RangeBsearchAlgorithm.new }
  let(:shard_maps) { ActiveRecord::Base.turntable_configuration.cluster(:user_cluster).shard_maps }
  let(:shards) { ActiveRecord::Base.turntable_configuration.cluster(:user_cluster).shards }

  context "#choose" do
    subject { algorithm.choose(shard_maps, key) }

    where :key, :target do
      [
        [1,      "user_shard_1"],
        [19999,  "user_shard_1"],
        [20000,  "user_shard_2"],
        [100000, "user_shard_3"],
      ]
    end

    with_them do
      its(:name) { is_expected.to eq(target) }
    end

    context "with a value overflowed range of shard_maps" do
      subject { algorithm.choose(shard_maps, 10_000_000) }

      it do
        expect { subject }.to raise_error(
          ActiveRecord::Turntable::CannotSpecifyShardError
        )
      end
    end
  end

  context "#shard_weights" do
    it "called with 10 returns { shards[0] => 10 }" do
      expect(algorithm.shard_weights(shard_maps, 10)).to eq({ shards[0] => 10 })
    end

    it "called with 25000 returns { shards[0] => 19999, shards[1] => 5001 }" do
      expect(algorithm.shard_weights(shard_maps, 25000)).to eq({ shards[0] => 19999, shards[1] => 5001 })
    end

    it "called with 65000 returns { shards[0] => 39999, shards[1] => 25001 }" do
      expect(algorithm.shard_weights(shard_maps, 65000)).to eq({ shards[0] => 39999, shards[1] => 25001 })
    end
  end
end
