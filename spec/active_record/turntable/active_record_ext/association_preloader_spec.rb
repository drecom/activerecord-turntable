require 'spec_helper'

describe ActiveRecord::Turntable::ActiveRecordExt::Association do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../../config/turntable.yml"))
  end

  before(:each) do
    establish_connection_to(:test)
    truncate_shard
  end

  let!(:user) do
    user = User.new({:nickname => 'user1'})
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

  context "When preloads has_many association" do
    before do
      ActiveRecord::Base.turntable_config.instance_variable_get(:@config)[:raise_on_not_specified_shard_query] = true
    end

    context "associated objects has same turntable_key" do
      subject { CardsUser.where(user: user).preload(:cards_users_histories).first }
      it { expect { subject }.to_not raise_error }

      it "its association should be loaded" do
        expect(subject.association(:cards_users_histories)).to be_loaded
      end

      it "its has_many targets should be assigned all related object" do
        expect(subject.cards_users_histories).to include(*cards_users_histories.select { |history| history.cards_user_id == subject.id} )
      end
    end

    context "associated objects has different turntable_key" do
      context "when foreign_shard_key option passed" do
        subject { CardsUser.where(user: user).preload(:events_users_histories_with_foreign_shard_key).first }

        it { expect { subject }.to_not raise_error }

        it "its association should be loaded" do
          expect(subject.association(:events_users_histories_with_foreign_shard_key)).to be_loaded
        end

        it "its has_many targets should be assigned all related object" do
          expect(subject.events_users_histories_with_foreign_shard_key).to include(*events_users_histories.select { |history| history.cards_user_id == subject.id} )
        end
      end

      context "when foreign_shard_key option is not passed" do
        subject { CardsUser.where(user: user).preload(:events_users_histories).first }

        it { expect { subject }.to raise_error }
      end
    end
  end
end
