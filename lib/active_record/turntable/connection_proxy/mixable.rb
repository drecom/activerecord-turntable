module ActiveRecord::Turntable
  class ConnectionProxy
    module Mixable
      extend ActiveSupport::Concern

      included do
        if ActiveRecord::VERSION::STRING < '3.1'
          include Rails30
        else
          include Rails3x
        end
      end

      module Rails3x
        METHODS_REGEXP = /\A(insert|select|update|delete|exec_)/
        EXCLUDE_QUERY_REGEXP = /\A\s*SHOW/i
        QUERY_REGEXP = /\A\s*(INSERT|DELETE|UPDATE|SELECT)/i

        def mixable?(method, *args)
          (method.to_s =~ METHODS_REGEXP &&
           args.first !~ EXCLUDE_QUERY_REGEXP) ||
            (method.to_s == 'execute' && args.first =~ QUERY_REGEXP)
        end
      end

      module Rails30
        METHODS_REGEXP = /\A(insert|select|update|delete)/
        EXCLUDE_QUERY_REGEXP = /\A\s*SHOW/i
        QUERY_REGEXP = /\A\s*(INSERT|DELETE|UPDATE|SELECT)/i

        def mixable?(method, *args)
          (method.to_s =~ METHODS_REGEXP &&
           args.first !~ EXCLUDE_QUERY_REGEXP) ||
            (method.to_s == 'execute' && args.first =~ QUERY_REGEXP)
        end
      end
    end
  end
end
