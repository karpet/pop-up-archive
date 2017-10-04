class AddTranscriptCostType < ActiveRecord::Migration
  def up
    add_column :transcripts, :cost_type, :integer, :null => false, :default => 1
  end

  def down
    drop_column :transcripts, :cost_type
  end
end
