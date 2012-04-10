require 'spec_helper'

describe ActiveRecord::Turntable::Algorithm do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../config/turntable.yml"))
  end

  describe ActiveRecord::Turntable::Algorithm::RangeBsearchAlgorithm do
    let(:algorithm) { ActiveRecord::Turntable::Algorithm::RangeBsearchAlgorithm.new(ActiveRecord::Base.turntable_config[:clusters][:user_cluster]) }
    context "#calculate" do
      it "called with 1 returns user_shard_1" do
        algorithm.calculate(1).should == "user_shard_1"
      end

      it "called with 100000 returns user_shard_3" do
        algorithm.calculate(100000).should == "user_shard_3"
      end
    end

    context "#calculate_used_shards_with_weight" do
      it "called with 10 returns 1 item" do
        algorithm.calculate_used_shards_with_weight(10).should have(1).items
      end

      it "called with 10 returns {\"user_shard_1\" => 10}" do
        algorithm.calculate_used_shards_with_weight(10).should == {"user_shard_1" => 10}
      end

      it "called with 65000 returns 2 items" do
        algorithm.calculate_used_shards_with_weight(65000).should have(2).items
      end

      it "called with 65000 returns {\"user_shard_1\" => 39999, \"user_shard_2\" => 25001}" do
        algorithm.calculate_used_shards_with_weight(65000).should == {"user_shard_1" => 39999, "user_shard_2" => 25001}
      end
    end
  end

  describe ActiveRecord::Turntable::Algorithm::RangeAlgorithm do
    let(:algorithm) { ActiveRecord::Turntable::Algorithm::RangeAlgorithm.new(ActiveRecord::Base.turntable_config[:clusters][:user_cluster]) }
    context "#calculate" do
      it "called with 1 returns user_shard_1" do
        algorithm.calculate(1).should == "user_shard_1"
      end

      it "called with 100000 returns user_shard_3" do
        algorithm.calculate(100000).should == "user_shard_3"
      end
    end

    context "#calculate_used_shards_with_weight" do
      it "called with 10 returns 1 item" do
        algorithm.calculate_used_shards_with_weight(10).should have(1).items
      end

      it "called with 10 returns {\"user_shard_1\" => 10}" do
        algorithm.calculate_used_shards_with_weight(10).should == {"user_shard_1" => 10}
      end

      it "called with 65000 returns 2 items" do
        algorithm.calculate_used_shards_with_weight(65000).should have(2).items
      end

      it "called with 65000 returns {\"user_shard_1\" => 39999, \"user_shard_2\" => 25001}" do
        algorithm.calculate_used_shards_with_weight(65000).should == {"user_shard_1" => 39999, "user_shard_2" => 25001}
      end
    end
  end
end
