class ChangeIdentifierTypeInAudioFiles < ActiveRecord::Migration
  def change
  	change_column :audio_files, :identifier, :text, :limit => nil
  end
end
