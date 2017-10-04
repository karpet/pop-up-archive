class AddSpeakerToTimedTexts < ActiveRecord::Migration
  def change
    add_column :timed_texts, :speaker_id, :integer
  end
end
