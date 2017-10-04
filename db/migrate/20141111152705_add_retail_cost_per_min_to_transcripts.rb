class AddRetailCostPerMinToTranscripts < ActiveRecord::Migration
  def up
    add_column :transcripts, :retail_cost_per_min, :integer, :null => false, :default => 0
  end

  def down
    drop_column :transcripts, :retail_cost_per_min
  end
end
