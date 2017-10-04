class Tasks::DetectDerivativesTask < Task

  before_save :serialize_urls

  after_commit :start_detective, :on => :create
  after_commit :finish_if_all_detected, :on => :update

  def serialize_urls
    self.serialize_extra('urls')
  end

  def finish_task
    return unless audio_file
    # mark the audio_file as having processing complete?
    audio_file.update_attribute(:transcoded_at, DateTime.now)
    # trigger any other tasks that were depending on transcoding
    audio_file.check_tasks
  end

  def urls
    deserialize_extra('urls', HashWithIndifferentAccess.new)
  end

  def urls=(urls)
    self.extras = HashWithIndifferentAccess.new unless extras
    self.extras['urls'] = HashWithIndifferentAccess.new(urls)
  end

  def audio_file
    self.owner
  end

  def versions
    urls.keys.sort
  end

  def version_info(version)
    urls[version]
  end

  def all_detected?
    any_nil = versions.detect{|version| version_info(version)['detected_at'].nil?}
    !any_nil
  end

  def recover!
    if !self.owner
      self.extras['error'] = 'No owner/audio_file assigned'
      self.cancel!
    else
      begin
        if self.all_detected?
          self.finish!
        else
          self.extras['error'] = 'One or more versions un-detected'
          self.cancel!
        end
      rescue JSON::ParserError => err
        self.extras['error'] = "#{err}"
        self.cancel!
      end
    end 
  end

  def mark_version_detected(version)
    vi = version_info(version)
    if (vi && !vi['detected_at'])
      vi['detected_at'] = DateTime.now
      self.save!
    end
  end

  def finish_if_all_detected
    return if complete?
    return if cancelled?
    begin
      self.finish! if self.all_detected?
    rescue JSON::ParserError => err
      self.extras['error'] = "#{err}"
      self.cancel!
    end
  end

  def start_detective
    job_ids = []
    versions.each do |version|
      info = version_info(version)
      job_ids << start_worker(version, info['url'])
    end
    job_ids
  end

  def start_worker(version, url)
    CheckUrlWorker.perform_async(id, version, url) unless Rails.env.test?
  end

end
