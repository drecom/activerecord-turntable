require "spec_helper"

describe ActiveRecord::Turntable::ActiveRecordExt::SchemaDumper do
  def dump_schema
    stream = StringIO.new
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)
    stream.string
  end

  context "#dump" do
    subject { dump_schema }
    it { is_expected.to match(/create_sequence_for "users", force: :cascade, options: /) }
    it { is_expected.not_to match(/create_table "users_id_seq"/) }
    it { is_expected.not_to match(/create_sequence_for "users_id_seq".*?do/) }
  end
end
