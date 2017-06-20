require "spec_helper"

describe ActiveRecord::Turntable::ActiveRecordExt::AssociationPreloader do
  before do
    @user = create(:user)
    @cards_users = create_list(:cards_user, 10, :with_cards_users_history, :with_events_users_history, user: @user)
  end

  context "When preloads has_many association" do
    around do |example|
      ActiveRecord::Base.turntable_config.instance_variable_get(:@config)[:raise_on_not_specified_shard_query] = true
      example.run
      ActiveRecord::Base.turntable_config.instance_variable_get(:@config)[:raise_on_not_specified_shard_query] = false
    end

    context "When associated objects has the same shard key" do
      subject { CardsUser.where(user: @user).preload(:cards_users_histories).first }

      it { expect { subject }.not_to raise_error }

      it "its association should be loaded" do
        expect(subject.association(:cards_users_histories)).to be_loaded
      end

      it "its has_many targets should be assigned all related object" do
        cards_user = subject
        histories = CardsUsersHistory.where(cards_user: cards_user, user: @user).to_a
        expect(cards_user.cards_users_histories).to match_array(histories)
      end
    end

    context "associated objects has different turntable_key" do
      context "when foreign_shard_key option passed" do
        subject { CardsUser.where(user: @user).preload(:events_users_histories_with_foreign_shard_key).first }

        it { expect { subject }.not_to raise_error }

        it "its association should be loaded" do
          expect(subject.association(:events_users_histories_with_foreign_shard_key)).to be_loaded
        end

        it "its has_many targets should be assigned all related object" do
          cards_user = subject
          histories = EventsUsersHistory.where(cards_user: cards_user, events_user_id: @user).to_a
          expect(cards_user.events_users_histories_with_foreign_shard_key).to match_array(histories)
        end
      end

      context "when foreign_shard_key option is not passed" do
        subject { CardsUser.where(user: @user).preload(:events_users_histories).first }

        it { expect { subject }.to raise_error(ActiveRecord::Turntable::CannotSpecifyShardError) }
      end
    end
  end
end
