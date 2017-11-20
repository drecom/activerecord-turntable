module ActiveRecord::Turntable
  class Configuration
    module Loader
      extend ActiveSupport::Autoload

      autoload :YAML
      autoload :DSL
    end
  end
end
