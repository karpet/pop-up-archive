class ChangeTranscriptSubscriptionPlanId < ActiveRecord::Migration
  def change
    change_column :transcripts, :subscription_plan_id, :integer
  end
end
