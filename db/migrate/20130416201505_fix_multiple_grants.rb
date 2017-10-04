class FixMultipleGrants < ActiveRecord::Migration
  def up
    add_index :collection_grants, [:user_id, :collection_id], unique: true
  end

  def down
  end
end
