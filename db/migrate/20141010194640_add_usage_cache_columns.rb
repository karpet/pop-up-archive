class AddUsageCacheColumns < ActiveRecord::Migration
  def up
    change_table :users do |t|
      t.hstore :transcript_usage_cache
    end
    change_table :organizations do |t|
      t.hstore :transcript_usage_cache
    end
  end

  def down
  end
end
