class ChangeOriginalFileUrlTypeInAudioFiles < ActiveRecord::Migration
  def change
  	change_column :audio_files, :original_file_url, :text, :limit => nil
  end
end
