class AddDonorInfoToPayment < ActiveRecord::Migration
  def self.up
    add_column :payments, :firstname, :string
    add_column :payments, :lastname, :string
    add_column :payments, :email, :string
    add_column :payments, :phone, :string
  end

  def self.down
    remove_column :payments, :phone
    remove_column :payments, :email
    remove_column :payments, :lastname
    remove_column :payments, :firstname
  end
end
