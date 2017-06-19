require "spec_helper"

describe ActiveRecord::Turntable::ActiveRecordExt::LockingOptimistic do
  before do
    ActiveRecord::Base.turntable_config.instance_variable_get(:@config)[:raise_on_not_specified_shard_update] = true
  end

  after do
    ActiveRecord::Base.turntable_config.instance_variable_get(:@config)[:raise_on_not_specified_shard_update] = false
  end

  let(:user) { create(:user) }
  let(:user_status) { user.user_status }

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
