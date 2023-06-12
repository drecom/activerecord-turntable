require "spec_helper"

describe ActiveRecord::Turntable::ConnectionProxy do
  context "When initialized" do
    subject { ActiveRecord::Turntable::ConnectionProxy.new(User, cluster) }
    let(:cluster) { ActiveRecord::Base.turntable_configuration.cluster(:user_cluster) }
    its(:default_connection) { is_expected.to eql(ActiveRecord::Base.connection) }
  end

  context "User insert with id" do
    subject { User.create!(id: user_id) }

    where(:user_id) do
      [1, 20000, 20001]
    end

    with_them do
      it { expect { subject }.not_to raise_error }
      it do
        user = subject
        expect(user).to be_saved_to(user.turntable_shard)
      end
    end

    context "With a SQL Injection intensional value" do
      subject { User.create!(id: user_id, nickname: nickname_with_injection) }

      let(:user_id) { 30000 }
      let(:nickname_with_injection) { "hogehgoge'00" }

      it { expect { subject }.not_to raise_error }
      it do
        user = subject
        user.reload
        expect(user.nickname).to eq(nickname_with_injection)
      end
    end

    context "With an escaped strings value" do
      subject { User.create!(id: user_id, nickname: nickname_with_escaped_string) }

      let(:user_id) { 30000 }
      let(:nickname_with_escaped_string) { "hoge@\n@\\@@\\nhoge\\\nhoge\\n" }

      it { expect { subject }.not_to raise_error }
      it do
        user = subject
        user.reload
        expect(user.nickname).to eq(nickname_with_escaped_string)
      end
    end
  end

  context "When have no users" do
    it "User.#count should be zero" do
      expect(User.count).to be_zero
    end

    it "User.all should have no item" do
      expect(User.all.to_a).to have(0).items
    end
  end

  context "When have 2 Users in different shards" do
    before do
      @user_in_shard1 = create(:user, :in_shard1)
      @user_in_shard2 = create(:user, :in_shard2)
    end

    context "When updating user in shard1" do
      subject { @user_in_shard1.update!(nickname: new_nickname) }

      let(:new_nickname) { Faker::Name.unique.name }

      it { expect { subject }.not_to raise_error }
    end

    context "When updating user in shard2" do
      subject { @user_in_shard2.update!(nickname: new_nickname) }

      let(:new_nickname) { Faker::Name.unique.name }

      it { expect { subject }.not_to raise_error }
    end

    it { expect(User.where(id: [@user_in_shard1.id, @user_in_shard2.id]).all.size).to eq(2) }

    it "User.count is 2" do
      expect(User.count).to eq(2)
    end

    it "User.all returns 2 User object" do
      expect(User.all.size).to eq(2)
    end
  end

  context "#with_all" do
    before do
      @user_in_shard1 = create(:user, :in_shard1)
      @user_in_shard2 = create(:user, :in_shard2)
    end

    context "When calling User.count within the block" do
      subject do
        User.connection.with_all { User.count }
      end

      it { is_expected.to have(3).items }

      it "returns User.count of each shards" do
        expect(subject[0]).to eq(1)
        expect(subject[1]).to eq(1)
        expect(subject[2]).to eq(0)
      end
    end

    context "With false argument" do
      context "When block raises error" do
        subject { User.connection.with_all(false) { raise StandardError, "Unknown Error" } }

        it { expect { subject }.to raise_error(StandardError) }
      end
    end

    context "With false argument" do
      context "block raises error" do
        subject { User.connection.with_all(true) { raise StandardError, "Unknown Error" } }

        it { expect { subject }.not_to raise_error }
        it { is_expected.to have(3).items }
        it { expect(subject).to all(be_instance_of(StandardError)) }
      end
    end
  end

  context "When calling exists? with shard_key" do
    before do
      @user_in_shard1 = create(:user, id: 1)
      @user_in_shard2 = create(:user, :in_shard2)
    end

    subject { User.exists?(id: 1) }

    it { is_expected.to be_truthy }
  end

  context "When calling exists? with non-existed shard_key" do
    before do
      @user_in_shard1 = create(:user, id: 1)
      @user_in_shard2 = create(:user, :in_shard2)
    end

    subject { User.exists?(id: 3) }

    it { is_expected.to be_falsey }
  end

  context "When calling exists? with non shard_key" do
    before do
      @user_in_shard1 = create(:user, id: 1)
      @user_in_shard2 = create(:user, :in_shard1, nickname: nickname)
    end

    subject { User.exists?(nickname: nickname) }

    let(:nickname) { Faker::Name.unique.name }

    it { is_expected.to be_truthy }
  end

  context "When calling exists? with non-existed non shard_key" do
    before do
      @user_in_shard1 = create(:user, id: 1)
      @user_in_shard2 = create(:user, :in_shard1)
    end

    subject { User.exists?(nickname: Faker::Name.unique.name) }

    it { is_expected.to be_falsey }
  end

  context "#data_source_exists?" do
    subject { User.connection.data_source_exists?(:users) }

    it { is_expected.to be_truthy }
  end

  context "QueryCache functions" do
    let(:connection_proxy) { ActiveRecord::Turntable::ConnectionProxy.new(klass, cluster) }
    let(:klass) { User }
    let(:cluster) { ActiveRecord::Base.turntable_configuration.cluster(:user_cluster) }

    context "#cache" do
      it "query cache enabled all connections within the block" do
        result = connection_proxy.cache {
          klass.turntable_cluster.shards.map do |pool|
            pool.connection.query_cache_enabled
          end
        }

        expect(result).to all(be true)
      end

      it "each shard has one cache entry within the block" do
        result = connection_proxy.cache {
          User.all.to_a
          klass.turntable_cluster.shards.map do |shard|
            shard.connection.query_cache.dup
          end
        }
        expect(result).to all(have(1).item)
      end

      it "query cache deleted all shard outside of the block" do
        connection_proxy.cache {
          User.all.to_a
        }
        result = klass.turntable_cluster.shards.map do |shard|
          shard.connection.query_cache.dup
        end
        expect(result).to all(be_empty)
      end
    end

    context "#uncached" do
      before do
        connection_proxy.enable_query_cache!
      end

      after do
        connection_proxy.disable_query_cache!
      end

      it "query cache disabled all connections within the block" do
        result = connection_proxy.uncached {
          klass.turntable_cluster.shards.map do |pool|
            pool.connection.query_cache_enabled
          end
        }
        expect(result).to all(be false)
      end

      it "each shard has no cache entry within the block" do
        result = connection_proxy.uncached {
          User.all.to_a
          klass.turntable_cluster.shards.map do |shard|
            shard.connection.query_cache.dup
          end
        }
        expect(result).to all(be_empty)
      end
    end
  end

  context "#with_master" do
    before do
      @user = User.create!(id: 1)
    end

    subject { User.with_master { @user.turntable_shard.connection } }

    its(:turntable_shard_name) { is_expected.to eq("user_shard_1") }

    context "inside with_slave block" do
      subject do
        User.with_slave do
          User.with_master do
            @user.turntable_shard.connection
          end
        end

        its(:turntable_shard_name) { is_expected.to eq("user_shard_1") }
      end
    end
  end

  context "#with_slave" do
    before do
      @user = User.create!(id: 1)
    end

    subject { User.with_slave { @user.turntable_shard.connection } }

    its(:turntable_shard_name) { is_expected.to eq("user_shard_1_1") }

    context "inside transaction block" do
      subject do
        User.with_slave do
          User.connection.transaction do
            @user.turntable_shard.connection
          end
        end
      end

      its(:turntable_shard_name) { is_expected.to eq("user_shard_1") }
    end

    context "nested with_slave blocks" do
      context "outside of 2nd with_slave block" do
        subject do
          User.with_slave do
            User.with_slave {}
            @user.turntable_shard.connection
          end
        end

        its(:turntable_shard_name) { is_expected.to eq("user_shard_1_1") }
      end
    end
  end
end
