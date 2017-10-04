class AddTokenToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :token, :string
  end
end
