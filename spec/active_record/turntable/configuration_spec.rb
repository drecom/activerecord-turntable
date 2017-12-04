require "spec_helper"

describe ActiveRecord::Turntable::Configuration do
  context "when initialized" do
    subject { ActiveRecord::Turntable::Configuration.new }

    its(:clusters) { is_expected.to be_empty }
    its(:sequencers) { is_expected.to be_empty }
  end

  context ".load" do
    context "when yaml file passed" do
      subject { ActiveRecord::Turntable::Configuration.load(yaml_path, "test") }

      let(:yaml_path) { File.expand_path("../../config/turntable.yml", __dir__) }

      it { expect { subject }.not_to raise_error }
      its(:clusters) { is_expected.to have(5).items }
      its(:sequencers) { is_expected.to have(2).item }
    end

    context "when turntable ruby dsl file passed" do
      subject { ActiveRecord::Turntable::Configuration.load(config_path, "test") }

      let(:config_path) { File.expand_path("../../config/turntable.rb", __dir__) }

      it { expect { subject }.not_to raise_error }
      its(:clusters) { is_expected.to have(5).items }
      its(:sequencers) { is_expected.to have(1).item }
    end
  end
end
