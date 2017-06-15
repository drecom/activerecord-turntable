module ActiveRecord::Turntable
  module Compatibility
    def self.extended(base)
      base.instance_variable_set(:@_compatible_versions, [])
    end

    def [](version = ActiveRecord.gem_version.release)
      unless version.is_a?(Gem::Version)
        version = Gem::Version.new(version)
      end
      find_compatible_module(version)
    end
    alias_method :compatible_module, :[]

    def find_compatible_module(version)
      module_version = find_compatible_version(version)
      const_get("V#{module_version.to_s.tr(".", "_")}")
    end

    def find_compatible_version(version)
      target_version = nil

      compatible_versions.each do |compatible_version|
        break if version < compatible_version
        target_version = compatible_version
      end

      target_version
    end

    def compatible_versions
      if @_compatible_versions.empty?
        @_compatible_versions = constants.map do |const|
          /^V(?<major>\d+)(_(?<minor>\d+)(_(?<teeny>\d))?)?/ =~ const
          nil unless major
          Gem::Version.new([major, minor, teeny].compact.join("."))
        end
        @_compatible_versions.compact!
        @_compatible_versions.sort!
      end
      @_compatible_versions
    end
  end
end
