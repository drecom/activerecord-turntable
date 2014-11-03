module ActiveRecord::Turntable::Algorithm
  class Base
    def initialize(config)
      @config = config
    end

    def calculate(key)
      raise NotImplementedError, "not implemented"
    end
  end
end
