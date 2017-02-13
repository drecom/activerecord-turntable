require "spec_helper"

describe ActiveRecord::FinderMethods do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../config/turntable.yml"))
  end

  context "User insert with id" do
    before do
      establish_connection_to(:test)
      truncate_shard
      user
    end

    let(:user) {
      u = User.new
      u.id = 1
      u.save
      u
    }

    describe "User#find" do
      context "With existing users.id" do
        subject { User.find(1) }

        it "#find should be returns user" do
          is_expected.to eq(user)
        end
      end

      context "With users.id not existing" do
        subject { User.find(2) }

        it "#find should raise error" do
          expect { subject }.to raise_error
        end
      end
    end
  end
end
