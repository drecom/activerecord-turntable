module ActiveRecord::Turntable
  class Railtie < Rails::Railtie
    rake_tasks do
      require 'active_record/turntable/active_record_ext/database_tasks'
      load "active_record/turntable/railties/databases.rake"
    end

    # rails loading hook
    ActiveSupport.on_load(:before_initialize) do
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Base.send(:include, ActiveRecord::Turntable)
      end
    end

    # initialize
    initializer "turntable.initialize_clusters" do
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Turntable::Config.load!
      end
    end

    # QueryCache Middleware for turntable shards
    initializer "turntable.insert_query_cache_middleware" do |app|
      app.middleware.insert_after ActiveRecord::QueryCache, ActiveRecord::Turntable::Rack::QueryCache
    end
  end
end
