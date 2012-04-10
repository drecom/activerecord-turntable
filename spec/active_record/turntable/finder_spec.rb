require 'spec_helper'

describe "ActiveRecord::FinderMethods" do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../config/turntable.yml"))
  end

  context "User insert with id" do
    before do
      establish_connection_to("test")
      truncate_shard
      ActiveRecord::Base.logger = Logger.new(STDOUT)
      @user = User.new
      @user.id = 1
      @user.save
    end

    it "#find(1) should be == user" do
      User.find(1).should == @user
    end

    it "#find(2) should raise error" do
      lambda { User.find(2) }.should raise_error
    end
  end
end

