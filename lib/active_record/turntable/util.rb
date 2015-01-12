module ActiveRecord::Turntable
  module Util
    extend self

    def rails4?
      ActiveRecord::VERSION::MAJOR == 4
    end

    def rails41_later?
      rails4? && ActiveRecord::VERSION::MINOR >= 1
    end

    def rails42_later?
      rails4? && ActiveRecord::VERSION::MINOR >= 2
    end
  end
end
