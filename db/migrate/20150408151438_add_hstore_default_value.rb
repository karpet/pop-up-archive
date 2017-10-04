class AddHstoreDefaultValue < ActiveRecord::Migration
  def change
    change_column :items, :extra, :hstore, :default => ''
    change_column :tasks, :extras, :hstore, :default => ''
    change_column :users, :transcript_usage_cache, :hstore, :default => ''
    change_column :organizations, :transcript_usage_cache, :hstore, :default => ''
  end
end
