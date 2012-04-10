class User < ActiveRecord::Base
  turntable :user_cluster, :id
  sequencer
end
