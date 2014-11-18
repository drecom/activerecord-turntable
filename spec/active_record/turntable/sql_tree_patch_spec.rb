require 'spec_helper'
require 'active_record/turntable/sql_tree_patch'

describe SQLTree do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../config/turntable.yml"))
  end

  context "Insert query with binary string" do
    subject { SQLTree["INSERT INTO `hogehoge` (`name`) VALUES (x'deadbeef')"] }
    it { expect { subject }.to_not raise_error }
    its(:to_sql) { is_expected.to include("x'deadbeef") }
  end
end
