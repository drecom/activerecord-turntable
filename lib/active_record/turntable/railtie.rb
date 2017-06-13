module ActiveRecord::Turntable
  class Railtie < Rails::Railtie
    rake_tasks do
      require "active_record/turntable/active_record_ext/database_tasks"
      load "active_record/turntable/railties/databases.rake"
    end

    # rails loading hook
    ActiveSupport.on_load(:before_initialize) do
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Base.include(ActiveRecord::Turntable)
      end
    end

    # initialize
    initializer "turntable.initialize_clusters" do
      ActiveSupport.on_load(:active_record) do
        if File.exist?(ActiveRecord::Base.turntable_config_file)
          ActiveRecord::Turntable::Config.load!
        else
          warn("[activerecord-turntable] config/turntable.yml is not found. skipped initliazing cluster.")
        end
      end
    end

    # set QueryCache executor hooks for turntable clusters
    initializer "turntable.set_executor_hooks" do
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Turntable::ActiveRecordExt::QueryCache.install_turntable_executor_hooks
      end
    end
  end
end
