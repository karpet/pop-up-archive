class VoicebaseTranscriber < ActiveRecord::Migration
  def change

    execute "insert into transcribers (name, url, cost_per_min, description, created_at, updated_at) values ('voicebase', 'http://voicebase.com/', 50, 'voicebase', now(), now())"

  end
end
