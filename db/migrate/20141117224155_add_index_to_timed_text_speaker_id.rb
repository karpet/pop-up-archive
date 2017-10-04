class AddIndexToTimedTextSpeakerId < ActiveRecord::Migration
  def change
    add_index :timed_texts, :speaker_id
  end
end
