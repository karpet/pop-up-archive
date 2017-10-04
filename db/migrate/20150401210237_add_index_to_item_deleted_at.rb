class AddIndexToItemDeletedAt < ActiveRecord::Migration
  def change
    add_index :items, :deleted_at
  end
end
