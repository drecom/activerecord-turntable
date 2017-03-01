require "spec_helper"

describe ActiveRecord::Turntable::ActiveRecordExt::LockingOptimistic do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../../config/turntable.yml"))
  end

  before do
    establish_connection_to(:test)
    truncate_shard
    ActiveRecord::Base.turntable_config.instance_variable_get(:@config)[:raise_on_not_specified_shard_update] = true
  end

  after do
    ActiveRecord::Base.turntable_config.instance_variable_get(:@config)[:raise_on_not_specified_shard_update] = false
  end

  let!(:user_status) do
    user_status = UserStatus.new(user_id: 1)
    user_status.id = 10
    user_status.save
    user_status
  end

  describe "optimistic locking" do
    subject { user_status.update_attributes(hp: 20) }
    it { expect { subject }.to change(user_status, :lock_version).by(1) }
  end

  describe "Json serialized column is saved" do
    before do
      user_status.update_attributes(data: { foo: "bar" })
      user_status.reload
    end
    subject { user_status.data }
    it { expect { subject }.not_to raise_error }
  end
end
