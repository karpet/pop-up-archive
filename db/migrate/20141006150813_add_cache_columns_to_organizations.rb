class AddCacheColumnsToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :used_unmetered_hours_cache, :integer
    add_column :organizations, :used_metered_hours_cache, :integer
  end
end
