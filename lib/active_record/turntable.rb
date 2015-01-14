#
#= ActiveRecord::Turntable
#
# ActiveRecord Sharding Plugin
#
require 'active_record/turntable/version'
require 'active_record'
require 'active_record/fixtures'
require 'active_support/concern'
require 'active_record/turntable/error'
require 'active_record/turntable/util'
require 'logger'
require 'singleton'

# for 4.0.x series
module ActiveRecord
  unless respond_to?(:gem_version)
    class << self
      alias_method :gem_version, :version
    end
  end
end

module ActiveRecord::Turntable
  extend ActiveSupport::Concern
  extend ActiveSupport::Autoload

  eager_autoload do
    autoload :ActiveRecordExt
    autoload :Algorithm
    autoload :Base
    autoload :Cluster
    autoload :ClusterHelperMethods
    autoload :Config
    autoload :ConnectionProxy
    autoload :MasterShard
    autoload :Migration
    autoload :Mixer
    autoload :PoolProxy
    autoload :Shard
    autoload :SeqShard
    autoload :Sequencer
  end
  autoload :Rack
  autoload :Helpers

  included do
    include ActiveRecordExt
    include Base
  end

  module ClassMethods
    DEFAULT_PATH = File.dirname(File.dirname(__FILE__))

    def turntable_config_file
      @@turntable_config_file ||=
        File.join(defined?(::Rails) ?
                   ::Rails.root.to_s : DEFAULT_PATH, 'config/turntable.yml')
    end

    def turntable_config_file=(filename)
      @@turntable_config_file = filename
    end

    def turntable_config
      ActiveRecord::Turntable::Config.instance
    end
  end

  require "active_record/turntable/railtie" if defined?(Rails)
end
