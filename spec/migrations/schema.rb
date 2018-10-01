ActiveRecord::Schema.define do
  create_table :users, comment: "comment" do |t|
    t.string   :nickname
    t.string   :thumbnail_url
    t.binary   :blob
    t.datetime :joined_at
    t.datetime :deleted_at
    t.timestamps
  end
  create_sequence_for :users, comment: "comment"

  create_table :user_profiles do |t|
    t.belongs_to :user, null: false
    t.date       :birthday
    t.text       :data
    t.boolean    :published, null: false, default: false
    t.integer    :lock_version, null: false, default: 0
    t.datetime   :deleted_at, default: nil
    t.timestamps
  end
  create_sequence_for :user_profiles

  create_table :items do |t|
    t.string :name, null: false
    t.timestamps
  end

  create_table :user_items do |t|
    t.belongs_to :user,       null: false
    t.belongs_to :item,       null: false
    t.integer    :num,        null: false, default: 1
    t.datetime   :deleted_at, default: nil
    t.timestamps
  end
  create_sequence_for :user_items

  create_table :user_item_histories do |t|
    t.belongs_to :user,      null: false
    t.belongs_to :user_item, null: false
    t.timestamps
  end
  create_sequence_for :user_item_histories

  create_table :user_event_histories do |t|
    t.belongs_to :user,       null: false
    t.belongs_to :event_user, null: false
    t.belongs_to :user_item,  null: false
    t.string     :type,       default: nil
    t.timestamps
  end
  create_sequence_for :user_event_histories
end
