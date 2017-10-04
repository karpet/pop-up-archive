class FixerWorker
  include Sidekiq::Worker

  sidekiq_options :retry => 25

  def perform(job_params, task_id)
    begin
      fixer_client = Fixer::Client.new
      new_job = fixer_client.jobs.create({job: job_params}).job
      job_id = new_job.id
      task = Task.find task_id
      task.status = :working
      task.extras['fixer_job_id'] = job_id
      task.save!
    rescue Object=>exception
      raise "create_job: error: #{exception.class.name}: #{exception.message}\n\t#{exception.backtrace.join("\n\t")}"
    end 
    job_id
  end

end