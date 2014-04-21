require 'spec_helper'
require 'logger'

describe ActiveRecord::Turntable::ActiveRecordExt::CleverLoad do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../../config/turntable.yml"))
  end

  before(:each) do
    establish_connection_to("test")
    truncate_shard

    @user1 = User.new({:nickname => 'user1'})
    @user1.id = 1
    @user1.save
    @user1_status = @user1.create_user_status(:hp => 10, :mp => 10)
    @user2 = User.new({:nickname => 'user2'})
    @user2.id = 2
    @user2.save
    @user2_status = @user2.create_user_status(:hp => 20, :mp => 10)
    ActiveRecord::Base.logger = Logger.new(STDOUT)
  end

  context "When a model has has_one relation" do
    context "When call clever_load!" do
      before(:each) do
        @strio = StringIO.new
        ActiveRecord::Base.logger = Logger.new(@strio)
        @users = User.clever_load!(:user_status)
        puts @strio.string
      end
      it "should send merged user_status select query" do
        @strio.string.should =~ //
      end

      it "should target loaded" do
        if ActiveRecord::VERSION::STRING < "3.1"
          @users.each do |user|
            user.loaded_user_status?.should be_truthy
          end
        else
          @users.each do |user|
            user.association(:user_status).loaded?.should be_truthy
          end
        end
      end

      it "should assigned reverse relation" do
        skip "should be implemented"
      end
    end
  end

  context "When a model has belongs_to relation" do
    context "When call clever_load!" do
      before(:each) do
        @strio = StringIO.new
        @strio = StringIO.new
        ActiveRecord::Base.logger = Logger.new(@strio)
        @user_statuses = UserStatus.clever_load!(:user)
        puts @strio.string
      end

      it "should send merged user_status select query" do
        @strio.string.should =~ //
      end

      it "should target loaded" do
        if ActiveRecord::VERSION::STRING < "3.1"
          @user_statuses.each do |user_status|
            user_status.loaded_user?.should be_truthy
          end
        else
          @user_statuses.each do |user_status|
            user_status.association(:user).loaded?.should be_truthy
          end
        end
      end

      it "should assigned reverse relation" do
        skip "should be implemented"
      end
    end
  end

  context "When a model has has_many relation" do
    it "should send query only 2 times." do
      skip "not implemented yet"
    end
  end
end
