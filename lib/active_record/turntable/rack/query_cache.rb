require 'active_record/query_cache'

module ActiveRecord
  module Turntable
    module Rack
      class QueryCache < ActiveRecord::QueryCache
        class BodyProxy < ActiveRecord::QueryCache::BodyProxy
          def close
            @target.close if @target.respond_to?(:close)
          ensure
            klasses = [ActiveRecord::Base, *ActiveRecord::Base.turntable_connections.values]
            ActiveRecord::Base.connection_id = @connection_id
            klasses.each do |k|
              k.connection.clear_query_cache
              unless @original_cache_value
                k.connection.disable_query_cache!
              end
            end
          end
        end

        def call(env)
          old = ActiveRecord::Base.connection.query_cache_enabled
          klasses = [ActiveRecord::Base, *ActiveRecord::Base.turntable_connections.values]
          klasses.each do |k|
            k.connection.enable_query_cache!
          end

          status, headers, body = @app.call(env)
          [status, headers, BodyProxy.new(old, body, ActiveRecord::Base.connection_id)]
        rescue Exception => e
          klasses.each do |k|
            k.connection.clear_query_cache
            unless old
              k.connection.disable_query_cache!
            end
          end
          raise e
        end
      end
    end
  end
end
