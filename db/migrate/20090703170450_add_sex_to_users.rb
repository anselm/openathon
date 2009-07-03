class AddSexToUsers < ActiveRecord::Migration
  def self.up
     add_column :users, :address, :string
     add_column :users, :age, :string
     add_column :users, :sex, :string
     add_column :users, :phone, :string
     add_column :users, :sms, :boolean
  end
  def self.down
  end
end
