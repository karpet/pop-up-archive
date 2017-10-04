class SwitchMonthlyUsageIndexToUnique < ActiveRecord::Migration
  def up

    # drop existing
    remove_index :monthly_usages, name: 'index_entity_use_date'

    # must drop all data because we have some invalid, non-uniques. We can easily recreate with rake reports:recalculate_monthly
    execute "truncate monthly_usages"

    # add new
    add_index :monthly_usages, [:entity_id, :entity_type, :use, :month, :year], name: 'index_entity_use_date', unique: true

  end

  def down
  end
end
