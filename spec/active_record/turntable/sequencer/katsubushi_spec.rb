require "spec_helper"

describe ActiveRecord::Turntable::Sequencer::Katsubushi do
  let(:sequencer) { ActiveRecord::Turntable::Sequencer::Katsubushi.new(options) }
  let(:sequence_name) { "hogefuga" }
  let(:options) { { options: { servers: [{ host: "localhost", port: 11212 }], compress: true } }.with_indifferent_access }

  before do
    # TODO: delete this setting
    # In this test, memcached is used as a dummy katsubushi.
    # Since a binary protocol pull request for katsubushi is not merged yet.
    # After the pull request merged, the Docker container below is available for test.
    # https://hub.docker.com/r/katsubushi/katsubushi/
    require "dalli"
    server = options.dig(:options, :servers).first
    client = Dalli::Client.new("#{server[:host]}:#{server[:port]}")
    client.set("hogefuga", "400105924536045568")
  end

  describe "#next_sequence_value" do
    subject { sequencer.next_sequence_value("hogefuga") }
    it { is_expected.to be_kind_of(Integer) }
  end

  describe "#current_sequence_value" do
    subject { sequencer.current_sequence_value("hogefuga") }
    it { is_expected.to be_kind_of(Integer) }
  end
end
