class AddCostToMonthlyUsages < ActiveRecord::Migration
  def change
    add_column :monthly_usages, :cost, :decimal
  end
end
