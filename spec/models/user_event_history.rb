class UserEventHistory < ActiveRecord::Base
  turntable :event_cluster, :event_user_id
  sequencer :user_seq

  belongs_to :user
  belongs_to :user_item
end
