require "spec_helper"

describe ActiveRecord::Turntable::ActiveRecordExt::Association do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../../config/turntable.yml"))
  end

  before do
    establish_connection_to(:test)
    truncate_shard
  end

  let!(:user) do
    user = User.new({ nickname: "user1" })
    user.id = 1
    user.save
    user
  end

  let!(:cards_users) do
    10.times.map do
      CardsUser.create(user: user, card_id: 1)
    end
  end

  let!(:cards_users_histories) do
    cards_users.map do |cards_user|
      CardsUsersHistory.create(cards_user: cards_user, user: user)
    end
  end

  let!(:events_users_histories) do
    cards_users.map do |cards_user|
      EventsUsersHistory.create(cards_user: cards_user, user: user, events_user_id: user.id)
    end
  end

  context "When a model with has_one relation" do
    context "When the has_one associated object doesn't exists" do
      subject { user.user_status }
      it { expect { subject }.to_not raise_error }
    end
  end

  context "With has_many association" do
    before do
      ActiveRecord::Base.turntable_config.instance_variable_get(:@config)[:raise_on_not_specified_shard_query] = true
    end
    let(:cards_user) { CardsUser.where(user: user).first }
    let(:cards_users_history) { cards_users_histories.find { |history| history.user_id == user.id } }

    context "associated objects has same turntable_key" do
      context "AssociationRelation#to_a" do
        subject { cards_user.cards_users_histories.to_a }
        it { expect { subject }.to_not raise_error }
        it { is_expected.to include(*cards_users_histories.select { |history| history.cards_user_id == cards_user.id }) }
      end

      context "AssociationRelation#where" do
        subject { cards_user.cards_users_histories.where(id: cards_users_history.id).to_a }
        it { expect { subject }.to_not raise_error }
        it { is_expected.to include(cards_users_history) }
      end
    end

    context "associated objects has different turntable_key" do
      context "when foreign_shard_key option passed" do
        subject { cards_user.events_users_histories_with_foreign_shard_key.to_a }

        it { expect { subject }.to_not raise_error }
        it { is_expected.to include(*events_users_histories.select { |history| history.cards_user_id == cards_user.id }) }
      end

      context "when foreign_shard_key option is not passed" do
        subject { CardsUser.where(user: user).events_users_histories }

        it { expect { subject }.to raise_error }
      end
    end
  end
end
