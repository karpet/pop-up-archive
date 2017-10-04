class AddSubscriberPlanToTranscript < ActiveRecord::Migration
  def change
    add_column :transcripts, :subscription_plan_id, :numeric
  end
end
