module ActiveRecord::Turntable
  module Algorithm
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :Base
      autoload :RangeAlgorithm
      autoload :RangeBsearchAlgorithm
      autoload :ModuloAlgorithm
    end
  end
end
