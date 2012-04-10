require 'spec_helper'

describe ActiveRecord::Turntable::Cluster do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../config/turntable.yml"))
  end

  context "When initialized" do
    before do
      establish_connection_to("test")
      truncate_shard
    end

    subject { ActiveRecord::Turntable::Cluster.new(User, ActiveRecord::Base.turntable_config[:clusters][:user_cluster]) }
    its(:klass) { should == User }
    its(:shards) { should have(3).items }
  end
end
