require 'spec_helper'

describe ActiveRecord::Turntable::Algorithm do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../config/turntable.yml"))
  end

  describe ActiveRecord::Turntable::Algorithm::RangeBsearchAlgorithm do
    let(:algorithm) { ActiveRecord::Turntable::Algorithm::RangeBsearchAlgorithm.new(ActiveRecord::Base.turntable_config[:clusters][:user_cluster]) }
    context "#calculate" do
      it "called with 1 returns user_shard_1" do
        expect(algorithm.calculate(1)).to eq("user_shard_1")
      end

      it "called with 19999 returns user_shard_1" do
        expect(algorithm.calculate(19999)).to eq("user_shard_1")
      end

      it "called with 20000 returns user_shard_2" do
        expect(algorithm.calculate(20000)).to eq("user_shard_2")
      end

      it "called with 100000 returns user_shard_3" do
        expect(algorithm.calculate(100000)).to eq("user_shard_3")
      end
    end

    context "#calculate_used_shards_with_weight" do
      it "called with 10 returns 1 item" do
        expect(algorithm.calculate_used_shards_with_weight(10)).to have(1).items
      end

      it "called with 10 returns {\"user_shard_1\" => 10}" do
        expect(algorithm.calculate_used_shards_with_weight(10)).to eq({"user_shard_1" => 10})
      end

      it "called with 65000 returns 2 items" do
        expect(algorithm.calculate_used_shards_with_weight(65000)).to have(2).items
      end

      it "called with 65000 returns {\"user_shard_1\" => 39999, \"user_shard_2\" => 25001}" do
        expect(algorithm.calculate_used_shards_with_weight(65000)).to eq({"user_shard_1" => 39999, "user_shard_2" => 25001})
      end
    end
  end

  describe ActiveRecord::Turntable::Algorithm::RangeAlgorithm do
    let(:algorithm) { ActiveRecord::Turntable::Algorithm::RangeAlgorithm.new(ActiveRecord::Base.turntable_config[:clusters][:user_cluster]) }
    context "#calculate" do
      it "called with 1 returns user_shard_1" do
        expect(algorithm.calculate(1)).to eq("user_shard_1")
      end

      it "called with 19999 returns user_shard_1" do
        expect(algorithm.calculate(19999)).to eq("user_shard_1")
      end

      it "called with 20000 returns user_shard_2" do
        expect(algorithm.calculate(20000)).to eq("user_shard_2")
      end

      it "called with 100000 returns user_shard_3" do
        expect(algorithm.calculate(100000)).to eq("user_shard_3")
      end
    end

    context "#calculate_used_shards_with_weight" do
      it "called with 10 returns 1 item" do
        expect(algorithm.calculate_used_shards_with_weight(10)).to have(1).items
      end

      it "called with 10 returns {\"user_shard_1\" => 10}" do
        expect(algorithm.calculate_used_shards_with_weight(10)).to eq({"user_shard_1" => 10})
      end

      it "called with 65000 returns 2 items" do
        expect(algorithm.calculate_used_shards_with_weight(65000)).to have(2).items
      end

      it "called with 65000 returns {\"user_shard_1\" => 39999, \"user_shard_2\" => 25001}" do
        expect(algorithm.calculate_used_shards_with_weight(65000)).to eq({"user_shard_1" => 39999, "user_shard_2" => 25001})
      end
    end
  end

  describe ActiveRecord::Turntable::Algorithm::ModuloAlgorithm do
    let(:algorithm) { ActiveRecord::Turntable::Algorithm::ModuloAlgorithm.new(ActiveRecord::Base.turntable_config[:clusters][:user_cluster]) }
    context "#calculate" do
      it "called with 1 return user_shard_2" do
        expect(algorithm.calculate(1)).to eq("user_shard_2")
      end
      it "called with 3 return user_shard_2" do
        expect(algorithm.calculate(3)).to eq("user_shard_2")
      end
      it "called with 5 return user_shard_1" do
        expect(algorithm.calculate(5)).to eq("user_shard_1")
      end
    end
  end
end
