class AddNotesToTeams < ActiveRecord::Migration
  def self.up
    change_table :notes do |t|
      t.integer :team_id, :default => 0
    end
  end
  def self.down
  end
end
