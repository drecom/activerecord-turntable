module ActiveRecord::Turntable
  class TurntableError < StandardError; end
  class SequenceNotFoundError < TurntableError; end
  class CannotSpecifyShardError < TurntableError; end
  class DefaultShardNotConnected < TurntableError; end
  class UnknownOperatorError < TurntableError; end
  class InvalidConfigurationError < TurntableError; end
end
