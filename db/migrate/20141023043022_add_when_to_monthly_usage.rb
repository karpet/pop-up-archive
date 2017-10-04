class AddWhenToMonthlyUsage < ActiveRecord::Migration
  def change
    add_column :monthly_usages, :yearmonth, :string
    add_index :monthly_usages, :yearmonth
  end
end
