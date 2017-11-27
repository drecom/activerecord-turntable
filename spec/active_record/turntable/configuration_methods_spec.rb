require "spec_helper"

describe ActiveRecord::Turntable::ConfigurationMethods do
  context "#turntable_configuration_file" do
    around do |example|
      old_conf_path = ActiveRecord::Base.turntable_configuration_file
      example.run
      ActiveRecord::Base.turntable_configuration_file = old_conf_path
    end

    subject { ActiveRecord::Base.turntable_configuration_file }

    let(:rails_root) { "/path/to/rails_root" }

    it "returns Rails.root/config/turntable.yml default" do
      stub_const("Rails", Class.new)
      allow(Rails).to receive(:root) { rails_root }
      ActiveRecord::Base.turntable_configuration_file = nil
      is_expected.to eq(File.join(rails_root, "config/turntable.yml"))
    end
  end

  context "#turntable_configuration" do
    subject { ActiveRecord::Base.turntable_configuration }

    it { is_expected.to be_instance_of(ActiveRecord::Turntable::Configuration) }
  end
end
