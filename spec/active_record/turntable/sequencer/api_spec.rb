require "spec_helper"

describe ActiveRecord::Turntable::Sequencer::Api do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../../config/turntable.yml"))
  end

  let(:sequencer) { ActiveRecord::Turntable::Sequencer::Api.new(klass, options) }
  let(:sequence_name) { "hogefuga" }
  let(:klass) { Class.new }
  let(:api_host) { "example.example" }
  let(:api_port) { 80 }
  let(:options) { { "api_host" => api_host, "api_port" => api_port } }
  let(:api_response) { 1024 }

  let(:next_sequence_uri) { "http://#{api_host}/sequences/#{sequence_name}/new" }
  let(:current_sequence_uri) { "http://#{api_host}/sequences/#{sequence_name}" }

  describe "#next_sequence_value" do
    before do
      stub_request(:get, next_sequence_uri).to_return(body: api_response.to_s)
    end

    subject { sequencer.next_sequence_value(sequence_name) }
    it { is_expected.to be_kind_of(Integer) }
    it { is_expected.to eq api_response }
  end

  describe "#current_sequence_value" do
    before do
      stub_request(:get, current_sequence_uri).to_return(body: api_response.to_s)
    end

    subject { sequencer.current_sequence_value(sequence_name) }
    it { is_expected.to be_kind_of(Integer) }
    it { is_expected.to eq api_response }
  end
end
