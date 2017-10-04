class SyncStripeWithSubscriptionPlan < ActiveRecord::Migration
  def up
    change_table :subscription_plans do |t|
      t.string :name
      t.string :amount
      t.string :hours
      t.string :interval
    end
  end

  def down
  end
end
