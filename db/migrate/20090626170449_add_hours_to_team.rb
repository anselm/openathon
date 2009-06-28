class AddHoursToTeam < ActiveRecord::Migration
  def self.up
     add_column :teams, :hours, :string
     add_column :teams, :approved, :boolean, :default => false
  end

  def self.down
  end
end
