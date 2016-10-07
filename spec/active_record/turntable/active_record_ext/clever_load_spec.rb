require "spec_helper"
require "logger"

describe ActiveRecord::Turntable::ActiveRecordExt::CleverLoad do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../../config/turntable.yml"))
  end

  before(:each) do
    establish_connection_to(:test)
    truncate_shard

    @user1 = User.new({ nickname: "user1" })
    @user1.id = 1
    @user1.save
    @user1_status = @user1.create_user_status(hp: 10, mp: 10)
    @user2 = User.new({ nickname: "user2" })
    @user2.id = 2
    @user2.save
    @user2_status = @user2.create_user_status(hp: 20, mp: 10)
  end

  context "When a model has has_one relation" do
    context "When call clever_load!" do
      let(:users) { User.all.clever_load!(:user_status) }

      context "With their associations" do
        subject { users.map { |u| u.association(:user_status) } }

        it "should be association target loaded" do
          is_expected.to all(be_loaded)
        end
      end

      context "With their targets" do
        subject { users.map { |u| u.association(:user_status).target } }

        it "should be loaded target object" do
          is_expected.to all(be_instance_of(UserStatus))
        end
      end
    end
  end

  context "When a model has belongs_to relation" do
    context "When call clever_load!" do
      let(:user_statuses) { UserStatus.all.clever_load!(:user) }

      context "With their associations" do
        subject { user_statuses.map { |us| us.association(:user) } }

        it "should target loaded" do
          is_expected.to all(be_loaded)
        end
      end

      context "With their targets" do
        subject { user_statuses.map { |us| us.association(:user).target } }

        it "should be loaded target object" do
          is_expected.to all(be_instance_of(User))
        end
      end
    end
  end

  context "When a model has has_many relation" do
    it "should send query only 2 times." do
      skip "not implemented yet"
    end
  end
end
