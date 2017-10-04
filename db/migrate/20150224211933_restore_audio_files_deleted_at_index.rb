class RestoreAudioFilesDeletedAtIndex < ActiveRecord::Migration
  def change
    add_index :audio_files, [:item_id, :deleted_at]
  end
end
