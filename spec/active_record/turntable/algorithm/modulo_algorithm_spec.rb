require "spec_helper"

describe ActiveRecord::Turntable::Algorithm::ModuloAlgorithm do
  let(:algorithm) { ActiveRecord::Turntable::Algorithm::ModuloAlgorithm.new }
  let(:shard_maps) { ActiveRecord::Base.turntable_configuration.cluster(:mod_cluster).shard_maps }

  context "#choose" do
    subject { algorithm.choose(shard_maps, key) }

    where :key, :target do
      [
        [1,  "user_shard_2"],
        [2,  "user_shard_3"],
        [3,  "user_shard_1"],
      ]
    end

    with_them do
      its(:name) { is_expected.to eq(target) }
    end

    context "with not a number" do
      subject { algorithm.choose(shard_maps, "a") }

      it { expect { subject }.to raise_error(ActiveRecord::Turntable::CannotSpecifyShardError) }
    end
  end
end
