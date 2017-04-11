require "spec_helper"

require "logger"

describe ActiveRecord::Turntable::ActiveRecordExt::Persistence do
  around do |example|
    old = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = Logger.new("/dev/null")
    example.run
    ActiveRecord::Base.logger = old
  end

  context "When creating record" do
    context "with blob column" do
      subject { create(:user, blob: blob_value) }

      let(:blob_value) { "\123\123\123" }

      its(:blob) { is_expected.to eq(subject.reload.blob) }
    end
  end

  context "When the model is sharded by surrogate key" do
    let(:user) { create(:user, :created_yesterday) }

    context "When updating" do
      subject { user.update_attributes!(nickname: new_nickname) }

      let(:new_nickname) { Faker::Name.unique.name }

      it { expect { subject }.not_to raise_error }

      it do
        allow(ActiveRecord::Base.logger).to receive(:debug)
        subject
        expect(ActiveRecord::Base.logger).to have_received(:debug).with(/WHERE `users`\.`id` = #{user.id}[^\s]*$/)
      end

      it do
        subject
        expect(user).to be_saved_to(user.turntable_shard)
      end

      it { expect { subject }.to change(user, :updated_at) }
    end

    context "When destroying" do
      subject { user.destroy }

      it { expect { subject }.not_to raise_error }
      it "SQL condition includes a shard key" do
        strio = StringIO.new
        ActiveRecord::Base.logger = Logger.new(strio)
        subject
        expect(strio.string).to match(/WHERE `users`\.`id` = #{user.id}[^\s]*$/)
      end
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

      it "appends shard_key condition to queries when updating" do
        strio = StringIO.new
        ActiveRecord::Base.logger = Logger.new(strio)
        subject
        expect(strio.string).to match(/`cards_users`\.`user_id` = #{cards_user.user_id}[^\s]*($|\s)/)
      end

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
      it "appends shard_key condition to queries when destroying" do
        strio = StringIO.new
        ActiveRecord::Base.logger = Logger.new(strio)
        expect {
          cards_user.destroy
        }.not_to raise_error
        expect(strio.string).to match(/`cards_users`\.`user_id` = #{cards_user.user_id}[^\s]*($|\s)/)
      end
    end

    it "warns when creating without shard_key" do
      skip "doesn't need to implemented soon"
    end

    it { expect { cards_user.reload }.not_to raise_error }

    it "executes one query when reloading" do
      strio = StringIO.new
      ActiveRecord::Base.logger = Logger.new(strio)
      cards_user.reload
      expect(strio.string.split("\n").select { |stmt| stmt =~ /SELECT/ and stmt !~ /Turntable/ }).to have(1).items
    end

    it { expect { cards_user.touch }.not_to raise_error }

    it "executes one query when touching" do
      strio = StringIO.new
      ActiveRecord::Base.logger = Logger.new(strio)
      cards_user.touch
      expect(strio.string.split("\n").select { |stmt| stmt =~ /UPDATE/ and stmt !~ /Turntable/ }).to have(1).items
    end

    it { expect { cards_user.lock! }.not_to raise_error }

    it "executes one query when locking" do
      strio = StringIO.new
      ActiveRecord::Base.logger = Logger.new(strio)
      cards_user.lock!
      expect(strio.string.split("\n").select { |stmt| stmt =~ /SELECT/ and stmt !~ /Turntable/ }).to have(1).items
    end

    it { expect { cards_user.update_columns(num: 10) }.not_to raise_error }

    it "executes one query when update_columns" do
      strio = StringIO.new
      ActiveRecord::Base.logger = Logger.new(strio)
      cards_user.update_columns(num: 10)
      expect(strio.string.split("\n").select { |stmt| stmt =~ /UPDATE/ and stmt !~ /Turntable/ }).to have(1).items
    end
  end

  context "When the model is not sharded" do
    let(:card) { create(:card) }

    it { expect { card.save! }.not_to raise_error }

    it "doesn't append shard_key condition to queries when updating" do
      card.name = "barbaz"
      strio = StringIO.new
      ActiveRecord::Base.logger = Logger.new(strio)
      card.save!
      expect(strio.string).to match(/WHERE `cards`\.`id` = #{card.id}[^\s]*$/)
    end

    it { expect { card.destroy! }.not_to raise_error }

    it "doesn't append shard_key condition to queries when destroying" do
      strio = StringIO.new
      ActiveRecord::Base.logger = Logger.new(strio)
      card.destroy!
      expect(strio.string).to match(/WHERE `cards`\.`id` = #{card.id}[^\s]*$/)
    end
  end

  context "When call reload" do
    subject { cards_user.reload }

    let(:user) { create(:user) }
    let!(:cards_user) { user.cards_users.first }

    it { is_expected.to be_instance_of(CardsUser) }
    it { is_expected.to eq(cards_user) }
  end
end
