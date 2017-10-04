class AddAudioFileStatusCache < ActiveRecord::Migration
  def change
    add_column :audio_files, :status_code, 'char(1)'
  end
end
