require "spec_helper"

describe ActiveRecord::Turntable::Base do
  context "When installed to ActiveRecord::Base" do
    it "ActiveRecord::Base respond_to 'turntable'" do
      expect(ActiveRecord::Base).to respond_to(:turntable)
    end
  end

  context "When enable turntable on STI models" do
    subject { klass.new }

    context "With a STI parent class" do
      let(:klass) { UserEventHistory }

      its(:connection) { expect { subject }.not_to raise_error }
    end

    context "With a STI subclass" do
      let(:klass) { SpecialUserEventHistory }

      its(:connection) { expect { subject }.not_to raise_error }
    end
  end

  context ".clear_all_connections!" do
    before do
      ActiveRecord::Base.force_connect_all_shards!
    end

    subject { ActiveRecord::Base.clear_all_connections! }

    it "closes all connections" do
      expect { subject }.to change {
        ObjectSpace.each_object(ActiveRecord::ConnectionAdapters::Mysql2Adapter).count { |conn| conn.active? } }.to(0)
    end
  end
end
