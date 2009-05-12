class ChangeTeamStatusToBool < ActiveRecord::Migration
  def self.up
    add_column :teams, :active, :boolean, :default => true

    Team.all.each do |team|
      team.active = (team.teamstatus == 'active')
      team.save!
    end

    remove_column :teams, :teamstatus
  end

  def self.down
    add_column :teams, :teamstatus, :string

    Team.all.each do |team|
      team.teamstatus = (team.active ? 'active' : 'retired')
      team.save!
    end

    remove_column :teams, :active
  end
end
