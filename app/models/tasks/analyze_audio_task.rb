class Tasks::AnalyzeAudioTask < Task

  after_commit :create_analyze_job, :on => :create

  def finish_task
    super
    return unless audio_file
    return if cancelled?
    analys = self.analysis || {}
    if !analys[:length]
      self.extras['error'] = "Analysis does not include length: #{self.id}, results: #{analys.inspect}"
      self.cancel! if audio_file.is_mp3?
      self.finish if !audio_file.is_mp3?
      return
    end
    audio_file.update_attribute(:duration, analys[:length].to_i) if analys[:length]
  end

  def recover!
    # most often status is 'working' but job has completed,
    # and there's just a timing issue in the db save and the worker running.
    # other times, the owner has been deleted.
    if self.results && self.results.empty?
      p "Analyze Audio Task, #{self.id.to_s}, working"
      return
    end

    if !audio_file
      self.extras['error'] = "No owner/audio_file found"
      cancel!
    else

      # if there is no analysis or analysis.length then finish_task will fail,
      # so just cancel and log error
      analys = self.analysis
      if !analys or !analys[:length]
        if !self.original
          self.extras['error'] = "No original URL and no analysis"
          self.cancel!
          return
        else
          self.extras['error'] = "Analysis does not include length: #{self.id}, results: #{analys.inspect}"
          self.cancel! if audio_file.is_mp3?
          self.finish if !audio_file.is_mp3?
          return
        end
      end

      finish!
    end
  end

  def analysis
    self.results[:info]
  end

  # :nocov:
  def create_analyze_job
    j = create_job do |job|
      job.job_type    = 'audio'
      job.original    = original
      job.retry_delay = Task::RETRY_DELAY
      job.retry_max   = Task::MAX_WORKTIME / Task::RETRY_DELAY
      if self.owner.item.extra['fixer_queue'] == "batch_processor"
        job.priority  = 5
      else
        job.priority  = 3
      end
      job.tasks       = []
      job.tasks << {
        task_type: 'analyze',
        label:     self.id,
        call_back: call_back_url
      }
      job
    end
  end
  # :nocov:

  def audio_file
    self.owner
  end

end
