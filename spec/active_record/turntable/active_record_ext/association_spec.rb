require 'spec_helper'

describe ActiveRecord::Turntable::ActiveRecordExt::Association do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../../config/turntable.yml"))
  end

  before(:each) do
    establish_connection_to("test")
    truncate_shard

    @user = User.new({:nickname => 'user1'})
    @user.id = 1
    @user.save
  end

  context "When a model with has_one relation" do
    context "When the has_one associated object doesn't exists" do
      subject { @user.user_status }
      it { expect { subject }.to_not raise_error }
    end
  end
end
