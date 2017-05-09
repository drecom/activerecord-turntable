require "spec_helper"
require "logger"

describe ActiveRecord::Turntable::ActiveRecordExt::CleverLoad do
  before do
    create_list(:user, 2)
  end

  context "When a model has has_one relation" do
    context "When call clever_load!" do
      let(:users) { User.all.clever_load!(:user_profile) }

      context "With their associations" do
        subject { users.map { |u| u.association(:user_profile) } }

        it "makes association target loaded" do
          is_expected.to all(be_loaded)
        end
      end

      context "With their targets" do
        subject { users.map { |u| u.association(:user_profile).target } }

        it "loads target object" do
          is_expected.to all(be_instance_of(UserProfile))
        end
      end
    end
  end

  context "When a model has belongs_to relation" do
    context "When call clever_load!" do
      let(:user_profilees) { UserProfile.all.clever_load!(:user) }

      context "With their associations" do
        subject { user_profilees.map { |us| us.association(:user) } }

        it "makes target loaded" do
          is_expected.to all(be_loaded)
        end
      end

      context "With their targets" do
        subject { user_profilees.map { |us| us.association(:user).target } }

        it "loads target object" do
          is_expected.to all(be_instance_of(User))
        end
      end
    end
  end

  context "When a model has has_many relation" do
    it "sends query only 2 times." do
      skip "not implemented yet"
    end
  end
end
