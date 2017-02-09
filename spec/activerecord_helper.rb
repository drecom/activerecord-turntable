$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require 'active_record'
require 'activerecord-turntable'
ActiveRecord::Base.include(ActiveRecord::Turntable)
require "active_record/turntable/active_record_ext/database_tasks"
warn "[turntable] turntable injected."
