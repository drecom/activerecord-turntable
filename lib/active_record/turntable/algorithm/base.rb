module ActiveRecord::Turntable::Algorithm
  class Base
    def initialize(config)
      @config = config
    end

    def calculate(key)
      raise ActiveRecord::Turntable::NotImplementedError, "not implemented"
    end
  end
end
