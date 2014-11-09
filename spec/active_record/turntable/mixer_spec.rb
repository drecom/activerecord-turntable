require 'spec_helper'

describe ActiveRecord::Turntable::Mixer do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../config/turntable.yml"))
  end

  before do
    establish_connection_to(:test)
    truncate_shard
    @cluster = ActiveRecord::Turntable::Cluster.new(User, ActiveRecord::Base.turntable_config[:clusters][:user_cluster])
    @connection_proxy = ActiveRecord::Turntable::ConnectionProxy.new(@cluster)
  end

  context "When initialized" do
    before do
      @mixer = ActiveRecord::Turntable::Mixer.new(@connection_proxy)
    end

    context "For Insert SQL" do
      context "When call divide_insert_values with Single INSERT and shard_key 'id'" do
        subject {
          tree = SQLTree["INSERT INTO `users` (id, hp, mp) VALUES (1, 10, 10)"]
          @mixer.send(:divide_insert_values, tree, "id")
        }

        it { is_expected.to be_instance_of(Hash) }
        it { is_expected.to have_key(1) }
        it { expect([1]).to have(1).item }
      end

      context "When call divide_insert_values with Bulk INSERT and shard_key 'id'" do
        subject {
          tree = SQLTree["INSERT INTO `users` (id, hp, mp) VALUES (1, 10, 10), (2,10,10), (3,10,10)"]
          @mixer.send(:divide_insert_values, tree, "id")
        }

        it { is_expected.to be_instance_of(Hash) }
        it { is_expected.to have_key(3) }
        it { expect([1]).to have(1).item }
        it { expect([2]).to have(1).item }
        it { expect([3]).to have(1).item }
      end
    end

    context "For Update SQL" do
      context "When call find_shard_keys with eql shardkey condition" do
        subject {
          tree = SQLTree["UPDATE `users` SET `users`.`hp` = 20 WHERE `users`.`id` = 1"]
          @mixer.find_shard_keys(tree.where, "users", "id")
        }

        it { is_expected.to be_instance_of Array }
        it { is_expected.to eq([1]) }
      end
    end

    context "For Delete SQL" do
      context "When call find_shard_keys with eql shardkey condition" do
        subject {
          tree = SQLTree["DELETE FROM `users` WHERE `users`.`id` = 1"]
          @mixer.find_shard_keys(tree.where, "users", "id")
        }

        it { is_expected.to be_instance_of Array }
        it { is_expected.to eq([1]) }
      end
    end

    context "For Select SQL" do
      context "When call find_shard_keys with eql shardkey condition" do
        subject {
          tree = SQLTree["SELECT * FROM `users` WHERE `users`.`id` = 1"]
          @mixer.find_shard_keys(tree.where, "users", "id")
        }

        it { is_expected.to be_instance_of Array }
        it { is_expected.to eq([1]) }
      end

      context "When call find_shard_keys with shardkey collection condition" do
        subject {
          tree = SQLTree["SELECT * FROM `users` WHERE `users`.`id` IN (1,2,3,4,5)"]
          @mixer.find_shard_keys(tree.where, "users", "id")
        }

        it { is_expected.to be_instance_of Array }
        it { is_expected.to eq([1,2,3,4,5]) }
      end

      context "When call find_shard_keys with not determine shardkey condition" do
        subject {
          tree = SQLTree["SELECT * FROM `users` WHERE `users`.`id` = 1 OR 1"]
          @mixer.find_shard_keys(tree.where, "users", "id")
        }

        it { is_expected.to be_instance_of Array }
        it { is_expected.to eq([]) }
      end

      context "When call find_shard_keys with except table definition SQL" do
        subject {
          tree = SQLTree["SELECT * FROM `users` WHERE id = 10"]
          @mixer.find_shard_keys(tree.where, "users", "id")
        }

        it { is_expected.to be_instance_of Array }
        it { is_expected.to eq([]) }
      end
    end

  end

end
