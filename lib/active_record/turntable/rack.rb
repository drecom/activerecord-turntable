module ActiveRecord::Turntable
  module Rack
    extend ActiveSupport::Autoload

    autoload :ConnectionManagement
    autoload :QueryCache
  end
end
