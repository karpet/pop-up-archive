class AddExtrasToUsers < ActiveRecord::Migration
  def change
    add_column :users, :extras, :hstore, :default => ''
  end
end
