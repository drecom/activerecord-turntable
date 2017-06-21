require "spec_helper"

describe ActiveRecord::Turntable::ActiveRecordExt::Association do
  before do
    @user = create(:user)
    @cards_users = create_list(:cards_user, 10, :with_cards_users_history, :with_events_users_history, user: @user)
  end

  context "When a model with has_one relation" do
    context "When the has_one associated object doesn't exists" do
      subject { @user.user_status }

      it { expect { subject }.not_to raise_error }
    end
  end

  context "With has_many association" do
    around do |example|
      ActiveRecord::Base.turntable_config.instance_variable_get(:@config)[:raise_on_not_specified_shard_query] = true
      example.run
      ActiveRecord::Base.turntable_config.instance_variable_get(:@config)[:raise_on_not_specified_shard_query] = false
    end

    let(:cards_user) { CardsUser.where(user: @user).first }

    context "associated objects has same turntable_key" do
      context "AssociationRelation#to_a" do
        subject { cards_user.cards_users_histories.to_a }

        it { expect { subject }.not_to raise_error }
        it do
          expected_histories = CardsUsersHistory.where(user: @user, cards_user: cards_user)
          is_expected.to match_array(expected_histories)
        end
      end

      context "AssociationRelation#where" do
        subject { cards_user.cards_users_histories.where(id: first_cards_users_history.id).to_a }

        let(:first_cards_users_history) { CardsUsersHistory.where(user: @user, cards_user: cards_user).first }

        it { expect { subject }.not_to raise_error }
        it { is_expected.to include(first_cards_users_history) }
      end
    end

    context "associated objects has different turntable_key" do
      context "when foreign_shard_key option passed" do
        subject { cards_user.events_users_histories_with_foreign_shard_key.to_a }

        it { expect { subject }.not_to raise_error }
        it do
          expected_histories = EventsUsersHistory.where(events_user_id: @user, cards_user: cards_user)
          is_expected.to match_array(expected_histories)
        end
      end

      context "when foreign_shard_key option is not passed" do
        subject { cards_user.events_users_histories.to_a }

        it { expect { subject }.to raise_error(ActiveRecord::Turntable::CannotSpecifyShardError) }
      end
    end
  end
end
