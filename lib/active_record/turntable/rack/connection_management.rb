module ActiveRecord::Turntable
  module Rack
    class ConnectionManagement
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env)
      ensure
        unless env.key?("rack.test")
          ActiveRecord::Base.connection_handler.clear_all_connections!
          ActiveRecord::Base.clear_all_connections!
        end
      end
    end
  end
end
