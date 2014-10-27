require 'spec_helper'
require 'logger'

describe ActiveRecord::Turntable::ActiveRecordExt::Persistence do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../../config/turntable.yml"))
  end

  before(:each) do
    establish_connection_to("test")
    truncate_shard
    ActiveRecord::Base.logger = Logger.new(STDOUT)
  end

  let(:user) {
    u = User.new({:nickname => 'foobar'})
    u.id = 1
    u.updated_at = Time.current - 1.day
    u.save
    u
  }
  let(:user_status){
    stat = user.create_user_status(:hp => 10, :mp => 10)
    stat.updated_at = Time.current - 1.day
    stat.save
    stat
  }
  let(:card){
    Card.create!(:name => 'foobar')
  }

  context "When the model is sharded by surrogate key" do
    it "should not changed from normal operation when updating" do
      user.nickname = "fizzbuzz"
      strio = StringIO.new
      ActiveRecord::Base.logger = Logger.new(strio)
      expect {
        user.save!
      }.to_not raise_error
      strio.string.should =~ /WHERE `users`\.`id` = #{user.id}[^\s]*$/
    end

    it "should be saved to target_shard" do
      expect(user).to be_saved_to(user.turntable_shard)
    end

    it "should change updated_at when updating" do
      user.nickname = "fizzbuzz"

      lambda {
        user.save!
      }.should change(user, :updated_at)
    end

    it "should not changed from normal operation when destroying" do
      strio = StringIO.new
      ActiveRecord::Base.logger = Logger.new(strio)
      expect {
        user.destroy
      }.to_not raise_error
      strio.string.should =~ /WHERE `users`\.`id` = #{user.id}[^\s]*$/
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
      user_status.hp = 20

      strio = StringIO.new
      ActiveRecord::Base.logger = Logger.new(strio)
      expect {
        user_status.save!
      }.to_not raise_error
      strio.string.should =~ /WHERE `user_statuses`\.`id` = #{user_status.id} AND `user_statuses`\.`user_id` = #{user_status.user_id}[^\s]*$/
    end

    it "should change updated_at when updating" do
      user_status.hp = 20

      lambda {
        user_status.save!
      }.should change(user_status, :updated_at)
    end

    it "should send shard_key condition when destroying" do
      strio = StringIO.new
      ActiveRecord::Base.logger = Logger.new(strio)
      expect {
        user_status.destroy
      }.to_not raise_error
      strio.string.should =~ /WHERE `user_statuses`\.`id` = #{user_status.id} AND `user_statuses`\.`user_id` = #{user_status.user_id}[^\s]*$/
    end

    it "should warn when creating without shard_key" do
      skip "doesn't need to implemented soon"
    end

    it "should execute one query when reloading" do
      user; user_status
      strio = StringIO.new
      ActiveRecord::Base.logger = Logger.new(strio)

      expect {
        user_status.reload
      }.to_not raise_error
      puts strio.string

      strio.string.split("\n").select {|stmt| stmt =~ /SELECT/ and stmt !~ /Turntable/ }.should have(1).items
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
      strio.string.should =~ /WHERE `cards`\.`id` = #{card.id}[^\s]*$/
    end

    it "should not send shard_key condition when destroying" do
      strio = StringIO.new
      ActiveRecord::Base.logger = Logger.new(strio)
      expect {
        card.destroy
      }.to_not raise_error
      strio.string.should =~ /WHERE `cards`\.`id` = #{card.id}[^\s]*$/
    end
  end

  context "When call reload" do
    subject { user_status.reload }
    it { should be_instance_of(UserStatus)}
    it { should == user_status }
  end

end
