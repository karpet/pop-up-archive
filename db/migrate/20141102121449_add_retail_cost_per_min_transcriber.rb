class AddRetailCostPerMinTranscriber < ActiveRecord::Migration
  def up
    add_column :transcribers, :retail_cost_per_min, :integer, :null => false, :default => 0
  end

  def down
    drop_column :transcribers, :retail_cost_per_min
  end
end
