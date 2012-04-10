module ActiveRecord::Turntable
  class Error < StandardError; end
  class NotImplementedError < Error; end
  class SequenceNotFoundError < Error; end
  class CannotSpecifyShardError < Error; end
  class MasterShardNotConnected < Error; end
  class UnknownOperatorError < Error; end
end
