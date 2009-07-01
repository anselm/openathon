class AddNotesToTeams < ActiveRecord::Migration
  def self.up
    change_table :notes do |t|
      t.rename :uuid, :team_id
      t.change :team_id, :integer
      t.remove :provenance, :permissions, :score
    end
  end
  def self.down
    change_table :notes do |t|
      t.change :team_id, :string
      t.rename :team_id, :uuid
      t.add :provenance, :permissions, :score
    end
  end
end
