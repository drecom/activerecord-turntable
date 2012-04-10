module ActiveRecord::Turntable
  module Algorithm
    autoload :Base, "active_record/turntable/algorithm/base"
    autoload :RangeAlgorithm, "active_record/turntable/algorithm/range_algorithm"
    autoload :RangeBsearchAlgorithm, "active_record/turntable/algorithm/range_bsearch_algorithm"
  end
end
