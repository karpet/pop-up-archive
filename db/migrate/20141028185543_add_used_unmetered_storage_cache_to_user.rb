class AddUsedUnmeteredStorageCacheToUser < ActiveRecord::Migration
  def change
    add_column :users, :used_unmetered_storage_cache, :integer
  end
end
