module ActiveRecord::Turntable
  module ConfigurationMethods
    DEFAULT_PATH = File.dirname(File.dirname(__FILE__))

    def turntable_config_file
      @turntable_config_file ||= File.join(turntable_app_root_path, "config/turntable.yml")
    end

    def turntable_config_file=(filename)
      @turntable_config_file = filename
    end

    def turntable_app_root_path
      defined?(::Rails.root) ? ::Rails.root.to_s : DEFAULT_PATH
    end

    def turntable_config
      ActiveRecord::Turntable::Config.instance
    end
  end
end
