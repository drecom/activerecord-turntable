module ActiveRecord::Turntable
  module Util
    def ar_version_equals_or_later?(version)
      ar_version >= Gem::Version.new(version)
    end

    def ar_version_earlier_than?(version)
      ar_version < Gem::Version.new(version)
    end

    def ar_version
      ActiveRecord.gem_version
    end

    module_function :ar_version_equals_or_later?,
                    :ar_version_earlier_than?,
                    :ar_version
  end
end
