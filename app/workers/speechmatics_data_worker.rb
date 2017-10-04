class SpeechmaticsDataWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :sequential, :retry => 5

  def perform(task_id)
    begin
      t=Task.find(task_id)
      sm_payload = HTTParty.get("https://api.speechmatics.com/v1.0/user/#{ENV["SPEECHMATICS_USER_ID"]}/jobs/#{t.extras['job_id']}/transcript?auth_token=#{ENV["SPEECHMATICS_AUTH_TOKEN"]}")
      t.extras["job_callback"] = sm_payload
      t.save
    rescue => e
        raise e
    end
  end
end
