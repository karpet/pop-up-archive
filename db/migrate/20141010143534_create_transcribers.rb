class CreateTranscribers < ActiveRecord::Migration
  def up
    if !table_exists?(:transcribers)
      create_table :transcribers do |t|
        t.string :name
        t.string :url
        t.integer :cost_per_min
        t.text :description

        t.timestamps
      end
      # populate with known transcripts
      execute "insert into transcribers (name, url, cost_per_min, description, created_at, updated_at) values ('google_voice', '', 0, 'unofficial google voice api', now(), now())"
      execute "insert into transcribers (name, url, cost_per_min, description, created_at, updated_at) values ('speechmatics', 'http://speechmatics.com/', 62, 'speechmatics', now(), now())"
    end
  end

  def down
    drop_table :transcribers
  end
end
