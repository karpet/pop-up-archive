class CollectionGrantsUniqueIndex < ActiveRecord::Migration
  def up

    if index_exists?(:collection_grants, 'index_collection_grants_on_user_id_and_collection_id')
      remove_index :collection_grants, name: 'index_collection_grants_on_user_id_and_collection_id'
    end
    add_index :collection_grants, [:collection_id, :collector_id, :collector_type], name: 'index_collection_grant_collector_type_collection', unique: true
  end

  def down
  end
end
