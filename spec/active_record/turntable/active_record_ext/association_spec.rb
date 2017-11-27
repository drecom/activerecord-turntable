require "spec_helper"

describe ActiveRecord::Turntable::ActiveRecordExt::Association do
  before do
    @user = create(:user)
    @user_items = create_list(:user_item, 10, :with_user_item_history, :with_user_event_history, user: @user)
  end

  context "When a model with has_one relation" do
    context "When the has_one associated object doesn't exists" do
      subject { @user.user_profile }

      it { expect { subject }.not_to raise_error }
    end
  end

  context "With has_many association" do
    around do |example|
      ActiveRecord::Base.turntable_configuration.raise_on_not_specified_shard_query = true
      example.run
      ActiveRecord::Base.turntable_configuration.raise_on_not_specified_shard_query = false
    end

    let(:user_item) { UserItem.where(user: @user).first }

    context "associated objects has same turntable_key" do
      context "AssociationRelation#to_a" do
        subject { user_item.user_item_histories.to_a }

        it { expect { subject }.not_to raise_error }
        it do
          expected_histories = UserItemHistory.where(user: @user, user_item: user_item)
          is_expected.to match_array(expected_histories)
        end
      end

      context "AssociationRelation#where" do
        subject { user_item.user_item_histories.where(id: first_user_item_history.id).to_a }

        let(:first_user_item_history) { UserItemHistory.where(user: @user, user_item: user_item).first }

        it { expect { subject }.not_to raise_error }
        it { is_expected.to include(first_user_item_history) }
      end
    end

    context "associated objects has different turntable_key" do
      context "when foreign_shard_key option passed" do
        subject { user_item.user_event_histories_with_foreign_shard_key.to_a }

        it { expect { subject }.not_to raise_error }
        it do
          expected_histories = UserEventHistory.where(event_user_id: @user, user_item: user_item)
          is_expected.to match_array(expected_histories)
        end
      end

      context "when foreign_shard_key option is not passed" do
        subject { user_item.user_event_histories.to_a }

        it { expect { subject }.to raise_error(ActiveRecord::Turntable::CannotSpecifyShardError) }
      end
    end
  end
end
