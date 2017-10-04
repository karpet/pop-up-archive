class AddRetailCostToMonthlyUsage < ActiveRecord::Migration
  def up
    add_column :monthly_usages, :retail_cost, :numeric
  end

  def down
    drop_column :monthly_usages, :retail_cost
  end
end
