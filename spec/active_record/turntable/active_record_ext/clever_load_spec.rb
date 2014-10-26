require 'spec_helper'
require 'logger'

describe ActiveRecord::Turntable::ActiveRecordExt::CleverLoad do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../../config/turntable.yml"))
  end

  before(:each) do
    establish_connection_to(:test)
    truncate_shard

    @user1 = User.new({:nickname => 'user1'})
    @user1.id = 1
    @user1.save
    @user1_status = @user1.create_user_status(:hp => 10, :mp => 10)
    @user2 = User.new({:nickname => 'user2'})
    @user2.id = 2
    @user2.save
    @user2_status = @user2.create_user_status(:hp => 20, :mp => 10)
  end

  context "When a model has has_one relation" do
    context "When call clever_load!" do
      before(:each) do
        @users = User.clever_load!(:user_status)
      end

      it "should target loaded" do
        @users.each do |user|
          expect(user.association(:user_status).loaded?).to be_truthy
        end
      end

      it "should assigned reverse relation" do
        expect(@users).to all(satisfy { |u|
          u.user_status.association(:user).loaded?
        })
      end
    end
  end

  context "When a model has belongs_to relation" do
    context "When call clever_load!" do
      before(:each) do
        @user_statuses = UserStatus.clever_load!(:user)
      end

      it "should target loaded" do
        @user_statuses.each do |user_status|
          expect(user_status.association(:user).loaded?).to be_truthy
        end
      end

      it "should assigned reverse relation" do
        expect(@user_statuses).to all(satisfy { |us|
          us.user.association(:user_status).loaded?
        })
      end
    end
  end

  context "When a model has has_many relation" do
    it "should send query only 2 times." do
      skip "not implemented yet"
    end
  end
end
