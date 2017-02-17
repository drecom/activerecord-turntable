require "spec_helper"

describe ActiveRecord::Turntable do
  before(:all) do
    ActiveRecord::Base.include(ActiveRecord::Turntable)
  end

  context "#config_file" do
    it "returns Rails.root/config/turntable.yml default" do
      stub_const("Rails", Class.new)
      allow(Rails).to receive(:root) { "/path/to/rails_root" }
      ActiveRecord::Base.turntable_config_file = nil
      expect(ActiveRecord::Base.turntable_config_file).to eq("/path/to/rails_root/config/turntable.yml")
    end
  end

  context "#turntable_config_file=" do
    it "set `#turntable_config_file`" do
      ActiveRecord::Base.include(ActiveRecord::Turntable)
      filename = "hogefuga"
      ActiveRecord::Base.turntable_config_file = filename
      expect(ActiveRecord::Base.turntable_config_file).to eq(filename)
    end
  end

  context "#config" do
    subject { ActiveRecord::Base.turntable_config }
    it { is_expected.to be_instance_of(ActiveRecord::Turntable::Config) }
  end
end
