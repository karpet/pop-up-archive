class FKsNotNull < ActiveRecord::Migration
  def up
    execute "update transcripts set audio_file_id=0 where audio_file_id is null"
    execute "update tasks set owner_id=0 where owner_id is null"
    change_column :audio_files, :item_id, :integer, :null => false
    change_column :transcripts, :audio_file_id, :integer, :null => false
    change_column :tasks, :owner_id, :integer, :null => false
  end

  def down
    change_column :audio_files, :item_id, :integer, :null => true
    change_column :transcripts, :audio_file_id, :integer, :null => true
    change_column :tasks, :owner_id, :integer, :null => true
  end
end
