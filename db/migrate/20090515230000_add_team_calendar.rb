class AddTeamCalendar < ActiveRecord::Migration

  def self.up
    add_column :teams, :calendar, :string, :default => ""
  end

  def self.down
    remove_column :teams, :calendar
  end

end
