class CardsUser < ActiveRecord::Base
  turntable :user_cluster, :user_id
  sequencer :user_seq

  belongs_to :user
  belongs_to :card
end
