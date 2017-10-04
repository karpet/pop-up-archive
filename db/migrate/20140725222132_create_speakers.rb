class CreateSpeakers < ActiveRecord::Migration
  def change
    create_table :speakers do |t|
      t.integer :transcript_id
      t.string :name
      t.text :times
      t.timestamps
    end
  end
end
