require "spec_helper"
require "active_record/turntable/sql_tree_patch"

describe SQLTree do
  context "Insert query with binary string" do
    subject { SQLTree["INSERT INTO `hogehoge` (`name`) VALUES (x'deadbeef')"] }
    it { expect { subject }.not_to raise_error }
    its(:to_sql) { is_expected.to include("x'deadbeef") }
  end

  context "Select query with index hint" do
    ["FORCE INDEX", "IGNORE INDEX", "USE INDEX"].each do |hint|
      context hint do
        subject { SQLTree["SELECT * FROM table #{hint} (`foo`) WHERE field = 'value'"] }
        it { expect { subject }.not_to raise_error }
        its(:to_sql) { is_expected.to include("#{hint} (`foo`)") }
      end
    end
  end

  context "Select query without index hint" do
    subject { SQLTree["SELECT * FROM table WHERE field = 'value'"] }
    it { expect { subject }.not_to raise_error }
  end

  context "Select query with inspect" do
    subject { SQLTree["SELECT * FROM table WHERE field = 'value' /* loading for inspect */ LIMIT 11"] }
    it { expect { subject }.not_to raise_error }
  end

  context "Delete query" do
    subject { SQLTree["DELETE FROM table"] }
    it { expect { subject }.not_to raise_error }
  end
end
