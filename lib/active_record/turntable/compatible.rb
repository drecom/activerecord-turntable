#
#=ActiveRecord::Turntable::Compatible
#
# for ActiveRecord versions compatibility
#
module ActiveRecord::Turntable
  module Compatible
    extend ActiveSupport::Concern

    included do
      # class_attributes
      unless respond_to?(:class_attribute)
        class << self
          alias_method :class_attribute, :class_inheritable_accessor
        end
      end
    end
  end
end
