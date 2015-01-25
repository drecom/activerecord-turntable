require 'spec_helper'

require 'active_record'
require 'active_record/turntable/active_record_ext/fixtures'

describe ActiveRecord::TestFixtures do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../../config/turntable.yml"))
  end

  before do
    establish_connection_to(:test)
    truncate_shard
  end

  let(:fixtures_root) { File.join(File.dirname(__FILE__), "../../../fixtures") }
  let(:fixture_file) { File.join(fixtures_root, "cards.yml") }
  let(:test_fixture_class) { Class.new(ActiveSupport::TestCase) { include ActiveRecord::TestFixtures } }
  let(:test_fixture) { test_fixture_class.new("test") }
  let(:cards) { YAML.load(ERB.new(IO.read(fixture_file)).result) }

  before do
    test_fixture_class.fixture_path = fixtures_root
  end

  describe "#setup_fixtures" do
    after do
      test_fixture.teardown_fixtures
    end

    subject { test_fixture.setup_fixtures }
    it { expect { subject }.not_to raise_error }
  end
end
