module ActiveRecord::Turntable
  class Railtie < Rails::Railtie
    rake_tasks do
      load "active_record/turntable/railties/databases.rake"
    end

    # rails loading hook
    ActiveSupport.on_load(:before_initialize) do
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Base.send(:include, ActiveRecord::Turntable)
      end
    end

    # Swap QueryCache Middleware
    initializer "turntable.swap_query_cache_middleware" do |app|
      app.middleware.swap ActiveRecord::QueryCache, ActiveRecord::Turntable::Rack::QueryCache
    end
  end
end
