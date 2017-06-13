require "spec_helper"
require "active_support/executor"

describe ActiveRecord::Turntable::ActiveRecordExt::QueryCache do
  def middleware(&app)
    executor = Class.new(ActiveSupport::Executor)
    ActiveRecord::QueryCache.install_executor_hooks executor
    lambda { |env| executor.wrap { app.call(env) } }
  end

  def disable_query_cache
    if ActiveRecord::Turntable::Util.ar_version_equals_or_later?("5.0.1")
      ActiveRecord::Base.connection_pool.disable_query_cache!
      ActiveRecord::Base.turntable_connections.values.each do |pool|
        pool.disable_query_cache!
      end
    else
      ActiveRecord::Base.connection.disable_query_cache!
      ActiveRecord::Base.turntable_connections.values.each do |pool|
        pool.connection.disable_query_cache!
      end
    end
  end

  def enable_query_cache
    if ActiveRecord::Turntable::Util.ar_version_equals_or_later?("5.0.1")
      ActiveRecord::Base.connection_pool.enable_query_cache!
      ActiveRecord::Base.turntable_connections.values.each do |pool|
        pool.enable_query_cache!
      end
    else
      ActiveRecord::Base.connection.enable_query_cache!
      ActiveRecord::Base.turntable_connections.values.each do |pool|
        pool.connection.enable_query_cache!
      end
    end
  end

  after do
    User.connection.cluster.shards.values.map { |s| s.connection.disable_query_cache! }
  end

  it "returns 200 response" do
    mw = middleware { |env| [200, {}, nil] }
    expect(mw.call({})).to eq([200, {}, nil])
  end

  it "each connection has one query cache when queries to all shard" do
    mw = middleware { |env|
      User.all.to_a
      User.connection.cluster.shards.values.map { |s| s.connection.query_cache.size }
    }
    expect(mw.call({})).to all(eq(1))
  end

  it "each connection has one query cache when queries to all shards" do
    mw = middleware { |env|
      User.find_by(id: 1)
      User.find_by(id: 1)

      User.connection.cluster.shards.values.map { |s| s.connection.query_cache.size }
    }
    expect(mw.call({})).to eq([1, 0, 0])
  end

  context "Outside of QueryCache middleware" do
    context "When disabled" do
      before { disable_query_cache }

      it "query cache disabled" do
        mw = middleware {}
        mw.call({})

        enables = User.connection.cluster.shards.values.map { |s| s.connection.query_cache_enabled }
        expect(enables).to all(be false)
      end
    end

    context "When enabled" do
      before { enable_query_cache }
      after { disable_query_cache }

      it "query cache enabled" do
        mw = middleware {}
        mw.call({})

        enables = User.connection.cluster.shards.values.map { |s| s.connection.query_cache_enabled }
        expect(enables).to all(be true)
      end
    end
  end


  it "target connection has one query cache when queries twice" do
    mw = middleware { |env|
      User.find_by(id: 1)
      User.find_by(id: 1)

      User.connection.cluster.shards.values.map { |s| s.connection.query_cache.size }
    }
    expect(mw.call({})).to eq([1, 0, 0])
  end
end
