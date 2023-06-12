require "spec_helper"
require "logger"

describe ActiveRecord::Turntable::ActiveRecordExt::Persistence do
  context "#reload" do
    subject { user_item.reload }

    let(:user) { create(:user, :with_user_items) }
    let!(:user_item) { user.user_items.first }

    it { is_expected.to be_instance_of(UserItem) }
    it { is_expected.to eq(user_item) }

    context "has blob value" do
      let(:user) { create(:user, blob: blob_value) }
      let(:blob_value) { "\123\123\123" }

      it { expect(user.blob).to eq(user.reload.blob) }
    end
  end

  context "When the model is sharded by surrogate key" do
    let(:user) { create(:user, :created_yesterday) }

    context "When updating" do
      subject { user.update!(nickname: new_nickname) }

      let(:new_nickname) { Faker::Name.unique.name }

      it { expect { subject }.not_to raise_error }
      it { expect { subject }.to query_like(/WHERE `users`\.`id` = #{user.id}[^\s]*$/) }

      it do
        subject
        expect(user).to be_saved_to(user.turntable_shard)
      end

      it { expect { subject }.to change(user, :updated_at) }
    end

    context "When destroying" do
      subject { user.destroy }

      it { expect { subject }.not_to raise_error }
      it { expect { subject }.to query_like(/WHERE `users`\.`id` = #{user.id}[^\s]*$/) }
    end
  end

  context "With a model with callbacks" do
    let(:user_with_callbacks) { create(:user_with_callbacks) }

    context "on update once" do
      subject { user_with_callbacks.save }

      it do
        allow(user_with_callbacks).to receive(:on_update)
        subject
        expect(user_with_callbacks).to have_received(:on_update).once
      end
    end

    context "on destroy once" do
      it do
        allow(user_with_callbacks).to receive(:on_destroy)
        user_with_callbacks.destroy
        expect(user_with_callbacks).to have_received(:on_destroy).once
      end
    end
  end

  context "When the model is sharded by other key" do
    let!(:user) { create(:user, :with_user_items) }
    let!(:user_item) { user.user_items.first }

    context "When updating" do
      subject { user_item.update!(num: 2) }

      it { expect { subject }.not_to raise_error }

      it { expect { subject }.to query_like(/`user_items`\.`user_id` = #{user_item.user_id}[^\s]*($|\s)/) }

      it "changes updated_at when updating" do
        Timecop.travel(1.day.from_now) do
          expect {
            user_item.num = 2
            subject
          }.to change(user_item, :updated_at)
        end
      end
    end

    context "When destroying" do
      subject { user_item.destroy! }

      it { expect { subject }.not_to raise_error }
      it { expect { subject }.to query_like(/`user_items`\.`user_id` = #{user_item.user_id}[^\s]*($|\s)/) }
    end

    it "warns when creating without shard_key" do
      skip "doesn't need to implemented soon"
    end

    context "#reload" do
      it { expect { user_item.reload }.not_to raise_error }
      it { expect { user_item.reload }.to have_queried(1) }
    end

    context "#touch" do
      it { expect { user_item.touch }.not_to raise_error }
      it { expect { user_item.touch }.to have_queried(1) }
    end

    context "#lock!" do
      it { expect { user_item.lock! }.not_to raise_error }
      it { expect { user_item.lock! }.to have_queried(1) }
    end

    context "#update_columns" do
      it { expect { user_item.update_columns(num: 10) }.not_to raise_error }
      it { expect { user_item.update_columns(num: 10) }.to have_queried(1) }
    end
  end

  context "When the model is not sharded" do
    let(:item) { create(:item) }

    it { expect { item.update(name: "hoge") }.not_to raise_error }
    it { expect { item.update(name: "hoge") }.to query_like(/WHERE `items`\.`id` = #{item.id}[^\s]*$/) }

    it { expect { item.destroy! }.not_to raise_error }
    it { expect { item.destroy! }.to query_like(/WHERE `items`\.`id` = #{item.id}[^\s]*$/) }
  end
end
