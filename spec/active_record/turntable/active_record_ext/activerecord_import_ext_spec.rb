require "spec_helper"
require "active_record/turntable/active_record_ext/activerecord_import_ext"

describe ActiveRecord::Turntable::ActiveRecordExt::ActiverecordImportExt do
  context "With sequencer enabled model" do
    subject { -> { UserItem.import(rows) } }

    let(:rows) do
      [
        build(:user_item, item: create(:item), user: create(:user, :in_shard1)),
        build(:user_item, item: create(:item), user: create(:user, :in_shard2)),
      ]
    end

    it { is_expected.not_to raise_error }
    it "creates one record on shard_1" do
      subject.call
      item_count = UserItem.with_shard(1) { UserItem.count }
      expect(item_count).to eq(1)
    end

    it "creates one record on shard_2" do
      subject.call
      item_count = UserItem.with_shard(20001) { UserItem.count }
      expect(item_count).to eq(1)
    end
  end
end
