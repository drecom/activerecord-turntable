require "spec_helper"

describe ActiveRecord::Turntable::Config do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../config/turntable.yml"))
  end

  subject { ActiveRecord::Turntable::Config }

  it "has config hash" do
    expect(subject.instance.instance_variable_get(:@config)).to be_an_kind_of(Hash)
  end

  it "has cluster setting" do
    expect(subject[:clusters][:user_cluster]).to be_instance_of(ActiveSupport::HashWithIndifferentAccess)
  end
end
