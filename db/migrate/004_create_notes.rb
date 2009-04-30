class CreateNotes < ActiveRecord::Migration
  def self.up
    create_table :notes do |t|

      t.string   :uuid
      t.string   :kind
      t.string   :provenance

      t.integer  :permissions
      t.integer  :owner_id
      t.integer  :depth
      t.integer  :score

      t.string   :title
      t.string   :link
      t.text     :description
      t.string   :depiction
      t.string   :location
      t.float    :lat
      t.float    :lon
      t.float    :radius
      t.datetime :begins
      t.datetime :ends

      t.timestamps
    end
  end
  def self.down
    drop_table   :notes
  end
end

