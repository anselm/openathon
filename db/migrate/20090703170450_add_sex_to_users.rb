class AddSexToUsers < ActiveRecord::Migration
  def self.up
     add_column :users, :address, :string
     add_column :users, :age, :string
     add_column :users, :sex, :string
     add_column :users, :phone, :string
     add_column :users, :optinsms, :boolean
     add_column :users, :optinethos, :boolean
     add_column :users, :optinvoicebox, :boolean
  end
  def self.down
  end
end
