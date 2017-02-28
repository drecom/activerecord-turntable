require "spec_helper"

describe ActiveRecord::Turntable do
  context "#config_file" do
    it "returns Rails.root/config/turntable.yml default" do
      stub_const("Rails", Class.new)
      allow(Rails).to receive(:root) { "/path/to/rails_root" }
      ActiveRecord::Base.turntable_configuration_file = nil
      expect(ActiveRecord::Base.turntable_configuration_file).to eq("/path/to/rails_root/config/turntable.yml")
    end
  end

  context "#turntable_configuration_file=" do
    it "set `#turntable_configuration_file`" do
      ActiveRecord::Base.include(ActiveRecord::Turntable)
      filename = "hogefuga"
      ActiveRecord::Base.turntable_configuration_file = filename
      expect(ActiveRecord::Base.turntable_configuration_file).to eq(filename)
    end
  end

  context "#config" do
    subject { ActiveRecord::Base.turntable_configuration }
    it { is_expected.to be_instance_of(ActiveRecord::Turntable::Config) }
  end
end
