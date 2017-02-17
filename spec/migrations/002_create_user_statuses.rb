class CreateUserStatuses < ActiveRecord::Migration
  def self.up
    create_table :user_statuses do |t|
      t.belongs_to :user, null: false
      t.integer    :hp,   null: false, default: 0
      t.integer    :mp,   null: false, default: 0
      t.datetime   :deleted_at, default: nil

      t.timestamps
    end
  end

  def self.down
    drop_table :user_statuses
  end
end
