require 'spec_helper'

describe ActiveRecord::Turntable::Config do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../config/turntable.yml"))
  end

  subject { ActiveRecord::Turntable::Config }

  it "has config hash" do
    subject.instance.instance_variable_get(:@config).should be_an_kind_of(Hash)
  end

  it "has cluster setting" do
    subject[:clusters][:user_cluster].should be_instance_of(ActiveSupport::HashWithIndifferentAccess)
  end
end
