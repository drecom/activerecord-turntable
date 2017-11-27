module ActiveRecord::Turntable
  class Configuration
    class Loader::DSL
      attr_reader :path, :configuration, :dsl

      def initialize(path, configuration = Configuration.new)
        @path = path
        @configuration = configuration
        @dsl = DSL.new(@configuration)
      end

      def self.load(path, configuration = Configuration.new)
        new(path, configuration).load
      end

      def load
        @dsl.instance_eval(File.read(@path), @path, 1)

        configuration
      end
    end
  end
end
