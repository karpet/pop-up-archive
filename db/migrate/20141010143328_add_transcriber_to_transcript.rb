class AddTranscriberToTranscript < ActiveRecord::Migration
  def change
    add_column :transcripts, :transcriber_id, :integer
    add_column :transcripts, :cost_per_min, :integer
    add_index :transcripts, :transcriber_id
  end
end
