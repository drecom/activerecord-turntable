module ActiveRecord::Turntable
  module Util
    def ar_version_equals_or_later?(version)
      ar_version >= Gem::Version.new(version)
    end

    def ar_version_earlier_than?(version)
      ar_version < Gem::Version.new(version)
    end

    def ar_version
      ActiveRecord.gem_version.release
    end

    def ar_version_satisfy?(requirement)
      unless requirement.is_a?(Gem::Requirement)
        requirement = Gem::Requirement.new(requirement)
      end
      requirement.satisfied_by?(ar_version)
    end

    def ar51?
      ar51_or_later? && !ar52_or_later?
    end

    def ar51_or_later?
      ar_version_equals_or_later?("5.1")
    end

    def earlier_than_ar51?
      ar_version_earlier_than?("5.1")
    end

    def ar52_or_later?
      ar_version_equals_or_later?("5.2")
    end

    def ar60_or_later?
      ar_version_equals_or_later?("6.0")
    end

    def ar61_or_later?
      ar_version_equals_or_later?("6.1")
    end

    module_function :ar_version_equals_or_later?,
                    :ar_version_earlier_than?,
                    :ar_version,
                    :ar_version_satisfy?,
                    :ar51?,
                    :earlier_than_ar51?,
                    :ar51_or_later?,
                    :ar52_or_later?,
                    :ar60_or_later?,
                    :ar61_or_later?
  end
end
