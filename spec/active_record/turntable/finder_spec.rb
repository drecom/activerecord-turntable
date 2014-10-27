require 'spec_helper'

describe "ActiveRecord::FinderMethods" do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../config/turntable.yml"))
  end

  context "User insert with id" do
    before do
      establish_connection_to(:test)
      truncate_shard
      @user = User.new
      @user.id = 1
      @user.save
    end

    it "#find(1) should be == user" do
      expect(User.find(1)).to eq(@user)
    end

    it "#find(2) should raise error" do
      expect { User.find(2) }.to raise_error
    end
  end
end
