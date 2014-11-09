class EventsUsersHistory < ActiveRecord::Base
  turntable :event_cluster, :events_user_id
  sequencer :user_seq

  belongs_to :user
  belongs_to :cards_user
end
