module ActiveRecord::Turntable
  class ConnectionProxy
    module Mixable
      extend ActiveSupport::Concern

      METHODS_REGEXP = /\A(insert|select|update|delete|exec_)/
      EXCLUDE_QUERY_REGEXP = /\A\s*SHOW/i
      QUERY_REGEXP = /\A\s*(INSERT|DELETE|UPDATE|SELECT)/i

      def mixable?(method, *args)
        (method.to_s =~ METHODS_REGEXP &&
         args.first.to_s !~ EXCLUDE_QUERY_REGEXP) ||
          (method.to_s == "execute" && args.first.to_s =~ QUERY_REGEXP)
      end
    end
  end
end
