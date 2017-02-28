require "spec_helper"

describe ActiveRecord::Turntable::ActiveRecordExt::AssociationPreloader do
  before do
    @user = create(:user)
    @user_items = create_list(:user_item, 10, :with_user_item_history, :with_user_event_history, user: @user)
  end

  context "When preloads has_many association" do
    around do |example|
      ActiveRecord::Base.turntable_configuration.instance_variable_get(:@config)[:raise_on_not_specified_shard_query] = true
      example.run
      ActiveRecord::Base.turntable_configuration.instance_variable_get(:@config)[:raise_on_not_specified_shard_query] = false
    end

    context "When associated objects has the same shard key" do
      subject { UserItem.where(user: @user).preload(:user_item_histories).first }

      it { expect { subject }.not_to raise_error }

      it "its association should be loaded" do
        expect(subject.association(:user_item_histories)).to be_loaded
      end

      it "its has_many targets should be assigned all related object" do
        user_item = subject
        histories = UserItemHistory.where(user_item: user_item, user: @user).to_a
        expect(user_item.user_item_histories).to match_array(histories)
      end
    end

    context "associated objects has different turntable_key" do
      context "when foreign_shard_key option passed" do
        subject { UserItem.where(user: @user).preload(:user_event_histories_with_foreign_shard_key).first }

        it { expect { subject }.not_to raise_error }

        it "its association should be loaded" do
          expect(subject.association(:user_event_histories_with_foreign_shard_key)).to be_loaded
        end

        it "its has_many targets should be assigned all related object" do
          user_item = subject
          histories = UserEventHistory.where(user_item: user_item, event_user_id: @user).to_a
          expect(user_item.user_event_histories_with_foreign_shard_key).to match_array(histories)
        end
      end

      context "when foreign_shard_key option is not passed" do
        subject { UserItem.where(user: @user).preload(:user_event_histories).first }

        it { expect { subject }.to raise_error(ActiveRecord::Turntable::CannotSpecifyShardError) }
      end
    end
  end
end
