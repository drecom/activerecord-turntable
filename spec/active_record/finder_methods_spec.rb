require "spec_helper"

describe ActiveRecord::FinderMethods do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../config/turntable.yml"))
  end

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

  context "#find" do
    context "pass an ID that exists" do
      subject { User.find(1) }

      it "returns user" do
        is_expected.to eq(user)
      end
    end

    context "pass an ID that doesn't exist" do
      subject { User.find(2) }

      it "raises error" do
        expect { subject }.to raise_error
      end
    end
  end
end
