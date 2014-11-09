module ActiveRecord::Turntable
  module Helpers
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :TestHelper
    end
  end
end
