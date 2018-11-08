require "spec_helper"
require "active_record/turntable/active_record_ext/connection_handler_extension"

describe ActiveRecord::Turntable::ActiveRecordExt::ConnectionHandlerExtension do
  it "connection_pool_list should not include PoolProxy" do
    expect(ActiveRecord::Base.connection_handler.connection_pool_list).to all(be_instance_of(ActiveRecord::ConnectionAdapters::ConnectionPool))
  end
end
