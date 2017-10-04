class AddIsBillableToTranscripts < ActiveRecord::Migration
  def up
    add_column :transcripts, :is_billable, :boolean, :null => false, :default => true
  end

  def down
    drop_column :transcripts, :is_billable
  end
end
