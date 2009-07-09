class AddMatchingCompanyToPayment < ActiveRecord::Migration
  def self.up
    add_column :payments, :matching_company, :string
  end

  def self.down
    remove_column :payments, :matching_company
  end
end
