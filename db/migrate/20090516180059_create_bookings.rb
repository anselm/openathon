class CreateBookings < ActiveRecord::Migration
  def self.up
    create_table :bookings do |t|
      t.integer :team_id
      t.string  :status
      t.string  :slot
      t.timestamps
    end
  end
  def self.down
    drop_table :bookings
  end
end
