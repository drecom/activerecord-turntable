require "spec_helper"

describe ActiveRecord::FinderMethods do
  before do
    @user = User.create!(id: 10)
  end

  context ".find" do
    context "pass an ID that exists" do
      subject { User.find(10) }

      it { is_expected.to eq(@user) }
    end

    context "pass an ID that doesn't exist" do
      subject { User.find(2) }

      it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
    end
  end
end
