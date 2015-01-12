module ActiveRecord::Turntable
  module Util
    extend self

    def ar_version_equals_or_later?(version)
      ar_version >= Gem::Version.new(version)
    end

    def ar_version_earlier_than?(version)
      ar_version < Gem::Version.new(version)
    end

    def ar4?
      ActiveRecord::VERSION::MAJOR == 4
    end

    def ar41_or_later?
      ar_version_equals_or_later?("4.1")
    end

    def earlier_than_ar41?
      ar_version_earlier_than?("4.1")
    end

    def ar42_or_later?
      ar_version_equals_or_later?("4.2")
    end

    def ar_version
      ActiveRecord::gem_version
    end
  end
end
