class AddParanoidToRoles < ActiveRecord::Migration
  def up
    add_column :roles, :deleted_at, :timestamp
    add_column :users_roles, :deleted_at, :timestamp
    add_column :organizations_roles, :deleted_at, :timestamp
    add_column :collection_grants, :deleted_at, :timestamp
  end

  def down
    remove_column :roles, :deleted_at
    remove_column :users_roles, :deleted_at
    remove_column :organizations_roles, :deleted_at
    remove_column :collection_grants, :deleted_at
  end
end
