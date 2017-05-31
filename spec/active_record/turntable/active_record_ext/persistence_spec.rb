require "spec_helper"
require "logger"

describe ActiveRecord::Turntable::ActiveRecordExt::Persistence do
  context "#reload" do
    subject { cards_user.reload }

    let(:user) { create(:user) }
    let!(:cards_user) { user.cards_users.first }

    it { is_expected.to be_instance_of(CardsUser) }
    it { is_expected.to eq(cards_user) }

    context "has blob value" do
      let(:user) { create(:user, blob: blob_value) }
      let(:blob_value) { "\123\123\123" }

      it { expect(user.blob).to eq(user.reload.blob) }
    end
  end

  context "When the model is sharded by surrogate key" do
    let(:user) { create(:user, :created_yesterday) }

    context "When updating" do
      subject { user.update_attributes!(nickname: new_nickname) }

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
    let(:user) { create(:user) }
    let!(:cards_user) { user.cards_users.first }

    context "When updating" do
      subject { cards_user.update_attributes!(num: 2) }

      it { expect { subject }.not_to raise_error }

      it { expect { subject }.to query_like(/`cards_users`\.`user_id` = #{cards_user.user_id}[^\s]*($|\s)/) }

      it "changes updated_at when updating" do
        Timecop.travel(1.day.from_now) do
          expect {
            cards_user.num = 2
            subject
          }.to change(cards_user, :updated_at)
        end
      end
    end

    context "When destroying" do
      subject { cards_user.destroy! }

      it { expect { subject }.not_to raise_error }
      it { expect { subject }.to query_like(/`cards_users`\.`user_id` = #{cards_user.user_id}[^\s]*($|\s)/) }
    end

    it "warns when creating without shard_key" do
      skip "doesn't need to implemented soon"
    end

    context "#reload" do
      it { expect { cards_user.reload }.not_to raise_error }
      it { expect { cards_user.reload }.to have_queried(1) }
    end

    context "#touch" do
      it { expect { cards_user.touch }.not_to raise_error }
      it { expect { cards_user.touch }.to have_queried(1) }
    end

    context "#lock!" do
      it { expect { cards_user.lock! }.not_to raise_error }
      it { expect { cards_user.lock! }.to have_queried(1) }
    end

    context "#update_columns" do
      it { expect { cards_user.update_columns(num: 10) }.not_to raise_error }
      it { expect { cards_user.update_columns(num: 10) }.to have_queried(1) }
    end
  end

  context "When the model is not sharded" do
    let(:card) { create(:card) }

    it { expect { card.update_attributes(name: "hoge") }.not_to raise_error }
    it { expect { card.update_attributes(name: "hoge") }.to query_like(/WHERE `cards`\.`id` = #{card.id}[^\s]*$/) }

    it { expect { card.destroy! }.not_to raise_error }
    it { expect { card.destroy! }.to query_like(/WHERE `cards`\.`id` = #{card.id}[^\s]*$/) }
  end
end
