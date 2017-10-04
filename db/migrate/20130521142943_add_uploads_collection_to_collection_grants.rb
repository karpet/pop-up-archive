class AddUploadsCollectionToCollectionGrants < ActiveRecord::Migration
  def change
    add_column :collection_grants, :uploads_collection, :boolean, default: false
  end
end
