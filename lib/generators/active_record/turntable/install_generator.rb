module ActiveRecord::Turntable
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../../../templates", __FILE__)

      desc "Creates turntable configuration file (config/turntable.yml)"
      class_option :orm

      def copy_locale
        copy_file "turntable.yml", "config/turntable.yml"
      end
    end
  end
end
