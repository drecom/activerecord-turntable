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

    context "In forked child process" do
      self.use_transactional_tests = false

      before do
        # release all connection on parent process
        ActiveRecord::Base.clear_all_connections!
      end

      it "closes all connections" do
        rd, wr = IO.pipe

        pid = fork {
          User.user_cluster_transaction {}
          ActiveRecord::Base.clear_all_connections!
          connected_count = ObjectSpace.each_object(ActiveRecord::ConnectionAdapters::ConnectionPool).count { |pool| pool.connections && pool.connected? }

          wr.write connected_count
          wr.close
          exit!
        }

        wr.close
        Process.waitpid pid
        connected_count = rd.read.to_i
        expect(connected_count).to eq(0)
        rd.close
      end
    end
  end
end
