class CreateTeams < ActiveRecord::Migration
  def self.up
    create_table :teams do |t|
      t.string :title
      t.string :description
      t.string :depiction
      t.string :teamstatus

      t.string :roomname
      t.datetime :roomtime

      t.timestamps
    end
  end

  def self.down
    drop_table :teams
  end
end
