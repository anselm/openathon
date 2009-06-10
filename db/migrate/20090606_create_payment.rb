class CreatePayment < ActiveRecord::Migration
  def self.up
    create_table :payments do |t|
      t.integer  :owner_id
      t.integer  :amount
      t.string   :title
      t.string   :link
      t.text     :description
      t.timestamps
    end
  end
  def self.down
    drop_table   :payments
  end
end

