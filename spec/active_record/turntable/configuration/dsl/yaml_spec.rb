require "spec_helper"

describe ActiveRecord::Turntable::Configuration::DSL::YAML do
  let(:yaml_configuration) { ActiveRecord::Turntable::Configuration::Loader::YAML.load(yaml_path, "test") }
  let(:yaml_path) { File.expand_path("../../../../config/turntable.yml", __dir__) }

  context "its sequencers" do
    let(:sequencers) { yaml_configuration.sequencers }

    it "instantiate given sequencer" do
      expect(sequencers[:barrage_seq]).to be_instance_of(ActiveRecord::Turntable::Sequencer::Barrage)
    end
  end
end
