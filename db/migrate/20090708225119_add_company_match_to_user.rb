class AddCompanyMatchToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :matching_company, :string
  end

  def self.down
    remove_column :users, :matching_company
  end
end
