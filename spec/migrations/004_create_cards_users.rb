class CreateCardsUsers < ActiveRecord::Migration
  def self.up
    create_table :cards_users do |t|
      t.belongs_to :card,    null: false
      t.belongs_to :user,    null: false
      t.datetime :deleted_at

      t.timestamps
    end
  end

  def self.down
    drop_table :cards_users
  end
end
