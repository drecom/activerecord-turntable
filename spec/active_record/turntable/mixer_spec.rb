require "spec_helper"

describe ActiveRecord::Turntable::Mixer do
  before do
    @cluster = ActiveRecord::Turntable::Cluster.new(ActiveRecord::Base.turntable_configuration[:clusters][:user_cluster])
    @connection_proxy = ActiveRecord::Turntable::ConnectionProxy.new(User, @cluster)
    @mixer = ActiveRecord::Turntable::Mixer.new(@connection_proxy)
  end

  context "#divide_insert_values" do
    subject { @mixer.send(:divide_insert_values, sql_tree, "id") }

    context "with a single insert sql expression" do
      let(:sql_tree) { SQLTree["INSERT INTO `users` (id, hp, mp) VALUES (1, 10, 10)"] }

      it { is_expected.to be_instance_of(Hash) }
      it { is_expected.to have_key(1) }
      it { is_expected.to have(1).item }
    end

    context "with a bulk insert sql expression" do
      let(:sql_tree) { SQLTree["INSERT INTO `users` (id, hp, mp) VALUES (1, 10, 10), (2,10,10), (3,10,10)"] }

      it { is_expected.to be_instance_of(Hash) }
      it { is_expected.to have_key(3) }
      it { expect(subject.values).to all(have(1).item) }
    end
  end

  context "#find_shard_keys" do
    subject { @mixer.find_shard_keys(sql_tree.where, "users", "id") }

    context "with an update sql expression includes an equals shard_key condition" do
      let(:sql_tree) { SQLTree["UPDATE `users` SET `users`.`hp` = 20 WHERE `users`.`id` = 1"] }

      it { is_expected.to be_instance_of Array }
      it { is_expected.to eq([1]) }
    end

    context "with a delete sql expression includes an equals shard_key condition" do
      let(:sql_tree) { SQLTree["DELETE FROM `users` WHERE `users`.`id` = 1"] }

      it { is_expected.to be_instance_of Array }
      it { is_expected.to eq([1]) }
    end

    context "with a select sql expression" do
      context "includes a single equals condition" do
        let(:sql_tree) { SQLTree["SELECT * FROM `users` WHERE `users`.`id` = 1"] }

        it { is_expected.to be_instance_of Array }
        it { is_expected.to eq([1]) }
      end

      context "includes duplicated equals conditions" do
        let(:sql_tree) { SQLTree["SELECT * FROM `users` WHERE `users`.`id` = 1 AND `users`.`id` = 1"] }

        it { is_expected.to be_instance_of Array }
        it { is_expected.to eq([1]) }
      end

      context "includes `IN` shard_key condition" do
        let(:sql_tree) { SQLTree["SELECT * FROM `users` WHERE `users`.`id` IN (1,2,3,4,5)"] }

        it { is_expected.to be_instance_of Array }
        it { is_expected.to eq([1, 2, 3, 4, 5]) }
      end

      context "couldn't determine shard_key by their conditions" do
        let(:sql_tree) { SQLTree["SELECT * FROM `users` WHERE `users`.`id` = 1 OR 1"] }

        it { is_expected.to be_instance_of Array }
        it { is_expected.to eq([]) }
      end

      context "includes shard_key conditions without table prefix" do
        let(:sql_tree) { SQLTree["SELECT * FROM `users` WHERE id = 10"] }

        it { is_expected.to be_instance_of Array }
        it { is_expected.to eq([]) }
      end
    end
  end
end
