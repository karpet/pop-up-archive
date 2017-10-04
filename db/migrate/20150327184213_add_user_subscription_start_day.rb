class AddUserSubscriptionStartDay < ActiveRecord::Migration
  def up
    add_column :users, :subscription_start_day, :integer
  end

  def down
    drop_column :users, :subscription_start_day
  end
end
