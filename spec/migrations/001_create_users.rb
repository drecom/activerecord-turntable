class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :nickname
      t.string :thumbnail_url
      t.binary :blob
      t.datetime :joined_at
      t.datetime :deleted_at

      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
