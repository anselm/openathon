class CreateRelations < ActiveRecord::Migration
  def self.up
    create_table :relations do |t|
      t.string   :kind
      t.text     :value
      t.integer  :note_id
      t.integer  :sibling_id
      t.timestamps
    end
  end
  def self.down
    drop_table   :relations
  end
end

