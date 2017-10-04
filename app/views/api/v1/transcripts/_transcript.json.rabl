attributes :language, :id

child timed_texts: 'parts' do
  attribute :id, :text, :start_time, :end_time, :speaker_id
end

child :speakers do |speaker|
  extends 'api/v1/speakers/speaker'
end
