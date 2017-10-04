class RenameCacheColumnsOnOrg < ActiveRecord::Migration
  def up
    rename_column :organizations, :used_unmetered_hours_cache, :used_unmetered_storage_cache
    rename_column :organizations, :used_metered_hours_cache, :used_metered_storage_cache
  end

  def down
    rename_column :organizations, :used_unmetered_storage_cache, :used_unmetered_hours_cache
    rename_column :organizations, :used_metered_storage_cache, :used_metered_hours_cache
  end
end
