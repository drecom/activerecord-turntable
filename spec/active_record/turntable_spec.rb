require 'spec_helper'

describe ActiveRecord::Turntable do
  before(:all) do
    ActiveRecord::Base.send(:include, ActiveRecord::Turntable)
  end

  context "#config_file" do
    it "should return Rails.root/config/turntable.yml default" do
      unless defined?(::Rails); class ::Rails; end; end
      Rails.stub(:root) { "/path/to/rails_root" }
      ActiveRecord::Base.turntable_config_file = nil
      ActiveRecord::Base.turntable_config_file.should == "/path/to/rails_root/config/turntable.yml"
    end
  end

  context "#config_file=" do
    it "should set config_file" do
      ActiveRecord::Base.send(:include, ActiveRecord::Turntable)
      filename = "hogefuga"
      ActiveRecord::Base.turntable_config_file = filename
      ActiveRecord::Base.turntable_config_file.should == filename
    end
  end

  context "#config" do
    subject { ActiveRecord::Base.turntable_config }
    it { should be_instance_of(ActiveRecord::Turntable::Config) }
  end
end
