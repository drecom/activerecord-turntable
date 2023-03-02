require "spec_helper"

describe ActiveRecord::Turntable::ActiveRecordExt::SchemaDumper do
  def dump_schema
    stream = StringIO.new
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)
    stream.string
  end

  context "#dump" do
    subject { dump_schema }

    if ActiveRecord::Turntable::Util.ar_version_equals_or_later?("6.1")
      it { is_expected.to match(/create_sequence_for "users", force: :cascade, charset: "[^"]+", comment: "[^"]+"/) }
    elsif ActiveRecord::Turntable::Util.ar_version_equals_or_later?("5.0.1")
      it { is_expected.to match(/create_sequence_for "users", force: :cascade, options: "[^"]+", comment: "[^"]+"$/) }
    else
      it { is_expected.to match(/create_sequence_for "users", force: :cascade, options: "[^"]+"/) }
    end
    it { is_expected.not_to match(/create_table "users_id_seq"/) }
    it { is_expected.not_to match(/create_sequence_for "users_id_seq".*?do/) }
  end
end
