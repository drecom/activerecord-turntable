module ActiveRecord::Turntable
  module ConfigurationMethods
    DEFAULT_PATH = File.dirname(File.dirname(__FILE__))

    def turntable_configuration_file
      @turntable_configuration_file ||= File.join(turntable_app_root_path, "config/turntable.yml")
    end
    alias_method :turntable_config_file, :turntable_configuration_file
    deprecate turntable_config_file: "use turntable_configuration_file instead", deprecator: ActiveRecord::Turntable::Deprecation.instance

    def turntable_configuration_file=(filename)
      @turntable_configuration_file = filename
    end
    alias_method :turntable_config_file=, :turntable_configuration_file=
    deprecate "turntable_config_file=": "use turntable_configuration_file= instead", deprecator: ActiveRecord::Turntable::Deprecation.instance

    def turntable_app_root_path
      defined?(::Rails.root) ? ::Rails.root.to_s : DEFAULT_PATH
    end

    def turntable_configuration
      ActiveRecord::Turntable::Config.instance
    end
    alias_method :turntable_config, :turntable_configuration
    deprecate turntable_config: "use turntable_configuration instead", deprecator: ActiveRecord::Turntable::Deprecation.instance
  end
end
