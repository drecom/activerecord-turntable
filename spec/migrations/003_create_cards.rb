class CreateCards < ActiveRecord::Migration
  def self.up
    create_table :cards do |t|
      t.string :name, null: false
      t.integer :hp,  null: false, default: 0
      t.integer :mp,  null: false, default: 0
      t.timestamps
    end
  end

  def self.down
    drop_table :cards
  end
end
