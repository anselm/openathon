class ChangeTeamTitleToName < ActiveRecord::Migration
  def self.up
  	rename_column :teams, :title, :name
  end

  def self.down
  	rename_column :teams, :name, :title
  end
end
