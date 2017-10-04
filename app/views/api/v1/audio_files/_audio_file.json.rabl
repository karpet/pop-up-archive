attributes :id, :filename, :transcoded_at, :duration, :current_status
attributes :urls => :url
attributes :transcript_type
attributes :has_premium_transcribe_task_in_progress? => :premium_in_progress
node :premium_retail_cost do |af|
  number_to_currency( af.premium_retail_cost ) 
end

child timed_transcript: 'transcript' do |t|
  extends 'api/v1/transcripts/transcript'
end

child tasks: 'tasks' do |c|
  extends 'api/v1/tasks/task'
end

if current_user
  node(:original, :if => lambda { |af| can?(:manage, af) }) do |af|
    af.url
  end
end
