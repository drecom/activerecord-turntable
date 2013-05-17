module ActiveRecord::Turntable
  module Rack
    autoload :ConnectionManagement, 'active_record/turntable/rack/connection_management'
    autoload :QueryCache, 'active_record/turntable/rack/query_cache'
  end
end
