class Tasks::CopyToS3Task < Task

  # copy a file from somewhere (original) to S3

  after_commit :create_copy_job, :on => :create

  def finish_task
    return unless owner

    # TODO flag the owner (audio_file) in any way to indicate the copy is complete?
  end

  # :nocov:
  def recover!
    if !owner
      extras['error'] = 'No owner defined'
      cancel!
    elsif !destination_exists?
      extras['error'] = 'Destination URL does not exist'
      cancel!
    else
      finish!
    end
  end
  # :nocov:

  # :nocov:
  def destination_exists?
    dest_url = URI.parse(extras['destination'])
    connection = Fog::Storage.new(storage.credentials)
    file_exists?(connection, dest_url)
  end 
  # :nocov:

  # :nocov:
  def create_copy_job
    j = create_job do |job|
      job.job_type    = 'audio'
      job.original    = original  # .mp3 file by default
      job.retry_delay = Task::RETRY_DELAY
      job.retry_max   = Task::MAX_WORKTIME / Task::RETRY_DELAY
      job.priority    = 1
      job.tasks = []
      job.tasks << {
        task_type: 'copy',
        label:     self.id,
        result:    destination,
        call_back: call_back_url
      }
      job
    end
  end
  # :nocov:

  def destination
    extras['destination'] || owner.try(:destination, {
      storage: StorageConfiguration.popup_storage
    })
  end

end
