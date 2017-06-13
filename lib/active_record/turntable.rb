#
#= ActiveRecord::Turntable
#
# ActiveRecord Sharding Plugin
#
require "active_record/turntable/version"
require "active_record"
require "active_record/fixtures"
require "active_support/concern"
require "active_record/turntable/error"
require "active_record/turntable/util"
require "logger"
require "singleton"

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
    autoload :ShardingCondition
    autoload :SeqShard
    autoload :Sequencer
  end

  included do
    include ActiveRecordExt
    include Base
  end

  module ClassMethods
    DEFAULT_PATH = File.dirname(File.dirname(__FILE__))

    def turntable_config_file
      @turntable_config_file ||= File.join(turntable_app_root_path, "config/turntable.yml")
    end

    def turntable_config_file=(filename)
      @turntable_config_file = filename
    end

    def turntable_app_root_path
      defined?(::Rails.root) ? ::Rails.root.to_s : DEFAULT_PATH
    end

    def turntable_config
      ActiveRecord::Turntable::Config.instance
    end

    def turntable_connection_classes
      ActiveRecord::Turntable::Shard.connection_classes
    end
  end

  require "active_record/turntable/railtie" if defined?(Rails)
end
