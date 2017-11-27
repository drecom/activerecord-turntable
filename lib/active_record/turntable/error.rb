module ActiveRecord::Turntable
  class TurntableError < StandardError; end
  class SequenceNotFoundError < TurntableError; end
  class CannotSpecifyShardError < TurntableError; end
  class MasterShardNotConnected < TurntableError; end
  class UnknownOperatorError < TurntableError; end
  class InvalidConfigurationError < TurntableError; end
end
