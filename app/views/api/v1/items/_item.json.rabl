attributes :id, :title, :description, :date_created, :identifier, :collection_id, :collection_title, :episode_title, :series_title, :date_broadcast, :physical_format, :digital_format, :digital_location, :physical_location, :music_sound_used, :date_peg, :rights, :duration, :tags, :transcript_type, :notes, :token, :language, :updated_at

Item::STANDARD_ROLES.each{|r| attribute r.pluralize.to_sym}

attribute created_at: :date_added

node (:storage) do |i|
  if i.storage
    i.storage.provider
  end
end

child :audio_files do |af|
  extends 'api/v1/audio_files/audio_file'
end

child :image_files do |af|
  extends 'api/v1/image_files/image_file'
end

child :entities do |e|
  extends 'api/v1/entities/entity'
end

node :extra do |i|
  i.extra
end

node(:urls) do |i|
  { self: url_for(sprintf("/api/collection/%s/items/%s", i.collection_id, i.id)) }
end

child :contributions do |c|
  extends 'api/v1/contributions/contribution'
end

node :highlights do |i|
  {}.tap do |o|
    o[:audio_files] = partial('api/v1/audio_files/audio_file', object: i.highlighted_audio_files) if i.respond_to? :highlighted_audio_files
  end
end
