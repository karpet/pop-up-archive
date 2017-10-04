class AddIndexToSpeakers < ActiveRecord::Migration
  def change
    add_index :speakers, :transcript_id
  end
end
