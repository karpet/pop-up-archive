class UserSubscriptionPlanId < ActiveRecord::Migration
  def up
    change_table :users do |t|
      t.integer :subscription_plan_id
    end
  end

  def down
  end
end
