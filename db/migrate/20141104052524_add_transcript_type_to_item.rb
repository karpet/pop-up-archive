class AddTranscriptTypeToItem < ActiveRecord::Migration
  def change
    add_column :items, :transcript_type, :string, :null => false, :default => "basic"
  end
end
