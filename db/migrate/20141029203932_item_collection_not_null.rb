class ItemCollectionNotNull < ActiveRecord::Migration
  def up
    change_column :items, :collection_id, :integer, :null => false
  end

  def down
    change_column :items, :collection_id, :integer, :null => true
  end
end
