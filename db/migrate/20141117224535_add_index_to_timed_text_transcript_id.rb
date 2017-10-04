class AddIndexToTimedTextTranscriptId < ActiveRecord::Migration
  def change
    add_index :timed_texts, :transcript_id
  end
end
