require "spec_helper"
require "logger"

describe ActiveRecord::Turntable::ActiveRecordExt::Persistence do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../../config/turntable.yml"))
  end

  before(:each) do
    establish_connection_to(:test)
    truncate_shard
  end

  around(:each) do |example|
    old = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    example.run
    ActiveRecord::Base.logger = old
  end

  let(:user) {
    u = User.new({ nickname: "foobar" })
    u.id = 1
    u.updated_at = Time.current - 1.day
    u.save
    u
  }
  let(:user_status) {
    stat = user.create_user_status(hp: 10, mp: 10)
    stat.updated_at = Time.current - 1.day
    stat.save
    stat
  }
  let(:card) {
    Card.create!(name: "foobar")
  }
  let(:cards_user) {
    user.cards_users.create(card: card)
  }
  context "When creating record" do
    context "with blob column" do
      let(:blob_value) { "\123\123\123" }
      let(:user) {
        u = User.new(nickname: "x", blob: blob_value)
        u.id = 1
        u.save
        u
      }
      subject { user }
      its(:blob) { is_expected.to eq(user.reload.blob) }
    end
  end

  context "When the model is sharded by surrogate key" do
    it "should not changed from normal operation when updating" do
      user.nickname = "fizzbuzz"
      strio = StringIO.new
      ActiveRecord::Base.logger = Logger.new(strio)
      expect {
        user.save!
      }.to_not raise_error
      expect(strio.string).to match(/WHERE `users`\.`id` = #{user.id}[^\s]*$/)
    end

    it "should be saved to target_shard" do
      expect(user).to be_saved_to(user.turntable_shard)
    end

    it "should change updated_at when updating" do
      user.nickname = "fizzbuzz"

      expect { user.save! }.to change(user, :updated_at)
    end

    it "should not changed from normal operation when destroying" do
      strio = StringIO.new
      ActiveRecord::Base.logger = Logger.new(strio)
      expect { user.destroy }.to_not raise_error
      expect(strio.string).to match(/WHERE `users`\.`id` = #{user.id}[^\s]*$/)
    end
  end

  context "When called Callbacks" do
    before do
      class ::User
        after_destroy :on_destroy
        after_save    :on_update

        def on_destroy
        end

        def on_update
        end
      end
    end

    context "on update once" do
      it "callback should be called once" do
        expect(user).to receive(:on_update).once
        user.save
      end
    end
    context "on destroy once" do
      it "callback should be called once" do
        expect(user).to receive(:on_destroy).once
        user.destroy
      end
    end
  end

  context "When the model is sharded by other key" do
    it "should send shard_key condition when updating" do
      cards_user.num = 10

      strio = StringIO.new
      ActiveRecord::Base.logger = Logger.new(strio)
      expect {
        cards_user.save!
      }.to_not raise_error
      expect(strio.string).to match(/`cards_users`\.`user_id` = #{cards_user.user_id}[^\s]*($|\s)/)
    end

    it "should change updated_at when updating" do
      cards_user

      Timecop.travel(1.day.from_now) do
        expect {
          cards_user.num = 2
          cards_user.save!
        }.to change(cards_user, :updated_at)
      end
    end

    it "should send shard_key condition when destroying" do
      strio = StringIO.new
      ActiveRecord::Base.logger = Logger.new(strio)
      expect {
        cards_user.destroy
      }.to_not raise_error
      expect(strio.string).to match(/`cards_users`\.`user_id` = #{cards_user.user_id}[^\s]*($|\s)/)
    end

    it "should warn when creating without shard_key" do
      skip "doesn't need to implemented soon"
    end

    it "should execute one query when reloading" do
      user; cards_user
      strio = StringIO.new
      ActiveRecord::Base.logger = Logger.new(strio)

      expect { cards_user.reload }.to_not raise_error

      expect(strio.string.split("\n").select { |stmt| stmt =~ /SELECT/ and stmt !~ /Turntable/ }).to have(1).items
    end

    it "should execute one query when touching" do
      user; cards_user
      strio = StringIO.new
      ActiveRecord::Base.logger = Logger.new(strio)

      expect { cards_user.touch }.to_not raise_error
      expect(strio.string.split("\n").select { |stmt| stmt =~ /UPDATE/ and stmt !~ /Turntable/ }).to have(1).items
    end

    it "should execute one query when locking" do
      user; cards_user
      strio = StringIO.new
      ActiveRecord::Base.logger = Logger.new(strio)

      expect { cards_user.lock! }.to_not raise_error
      expect(strio.string.split("\n").select { |stmt| stmt =~ /SELECT/ and stmt !~ /Turntable/ }).to have(1).items
    end

    it "should execute one query when update_columns" do
      user; cards_user
      strio = StringIO.new
      ActiveRecord::Base.logger = Logger.new(strio)

      expect { cards_user.update_columns(num: 10) }.to_not raise_error
      expect(strio.string.split("\n").select { |stmt| stmt =~ /UPDATE/ and stmt !~ /Turntable/ }).to have(1).items
    end
  end

  context "When the model is not sharded" do
    it "should not send shard_key condition when updating" do
      card.name = "barbaz"
      strio = StringIO.new
      ActiveRecord::Base.logger = Logger.new(strio)
      expect {
        card.save!
      }.to_not raise_error
      expect(strio.string).to match(/WHERE `cards`\.`id` = #{card.id}[^\s]*$/)
    end

    it "should not send shard_key condition when destroying" do
      strio = StringIO.new
      ActiveRecord::Base.logger = Logger.new(strio)
      expect {
        card.destroy
      }.to_not raise_error
      expect(strio.string).to match(/WHERE `cards`\.`id` = #{card.id}[^\s]*$/)
    end
  end

  context "When call reload" do
    subject { cards_user.reload }
    it { is_expected.to be_instance_of(CardsUser) }
    it { is_expected.to eq(cards_user) }
  end
end
