class AddDonationsToUsers < ActiveRecord::Migration
  def self.up
     add_column :users, :askeddonations, :boolean
     add_column :users, :invitedfriends, :boolean
     add_column :users, :showedup, :boolean
  end
  def self.down
  end
end
