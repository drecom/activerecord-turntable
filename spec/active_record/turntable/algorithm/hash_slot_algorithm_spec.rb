require "spec_helper"

describe ActiveRecord::Turntable::Algorithm::HashSlotAlgorithm do
  let(:algorithm) { ActiveRecord::Turntable::Algorithm::HashSlotAlgorithm.new(options) }
  let(:options) { {} }
  let(:shard_maps) { ActiveRecord::Base.turntable_configuration.cluster(:hash_slot_cluster).shard_maps }
  let(:shards) { ActiveRecord::Base.turntable_configuration.cluster(:hash_slot_cluster).shards }

  context "#choose" do
    subject { algorithm.choose(shard_maps, key) }

    where :key, :slot, :target do
      [
        [1, 1,      "user_shard_1"],
        [1, 4095,   "user_shard_1"],
        [1, 4096,   "user_shard_2"],
      ]
    end

    with_them do
      it do
        allow(algorithm).to receive(:slot_for_key) { slot }
        expect(subject.name).to eq(target)
      end
    end

    context "with a value overflowed range of shard_maps" do
      subject { algorithm.choose(shard_maps, 1) }

      it do
        allow(algorithm).to receive(:slot_for_key) { 16384 }
        expect { subject }.to raise_error(
          ActiveRecord::Turntable::CannotSpecifyShardError
        )
      end
    end
  end

  context "#slot_for_key" do
    subject { algorithm.slot_for_key(key, shard_maps.last.range.max) }

    where :key, :slot do
      [
        [1, 12215],
        [2, 15885],
        [3, 3739]
      ]
    end

    with_them do
      it { is_expected.to eq(slot) }
    end

    context "with customized hash_func" do
      let(:options) { { hash_func: ->(k) { k * 2 } } }

      where :key, :slot do
        [
          [1, 2],
          [2, 4],
          [3, 6]
        ]
      end

      with_them do
        it { is_expected.to eq(slot) }
      end
    end
  end

  context "#shard_weights" do
    subject { algorithm.shard_weights(shard_maps, 0) }

    it { is_expected.to have(4).items }
    its(:values) { is_expected.to all(eq(4096)) }
  end
end
