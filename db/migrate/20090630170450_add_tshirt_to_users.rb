class AddTshirtToUsers < ActiveRecord::Migration
  def self.up
     add_column :users, :tshirt, :string
     add_column :users, :optout, :boolean
     add_column :users, :tos, :boolean
  end

  def self.down
  end
end
