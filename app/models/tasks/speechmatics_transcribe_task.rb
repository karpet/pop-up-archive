require 'utils'
require 'speechmatics'

class Tasks::SpeechmaticsTranscribeTask < Task

  before_validation :set_speechmatics_defaults, :on => :create

  after_commit :create_transcribe_job, :on => :create

  def create_transcribe_job
    if self.owner.item.extra['fixer_queue'] == "batch_processor"
      ProcessTaskWorker.sidekiq_options_hash={"retry"=>0, "queue"=>"batch_processor"}
      ProcessTaskWorker.perform_async(self.id) unless Rails.env.test?
    else
      ProcessTaskWorker.perform_async(self.id) unless Rails.env.test?
    end
  end

  # :nocov:
  def process

    # sanity check -- have we already created a remote request?
    if self.extras['job_id']
      self.extras['log'] = 'process() called on existing job_id'
      return self
    end

    # do we actually have an owner?
    if !owner
      self.extras['error'] = 'No owner/audio_file found'
      self.save!
      return
    end

    # remember the temp file name so we can look up later
    data_url = URI.parse(audio_file_url)
    self.extras['sm_name'] = File.basename(data_url.path)
    self.save!

    # create the speechmatics job
    sm = Speechmatics::Client.new({ :request => { :timeout => 120 } })
    begin
      Timeout::timeout(60) do
        info = sm.user.jobs.create(
          data_url:     data_url,
          content_type: 'audio/mpeg; charset=binary',
          notification: 'callback',
          callback:     call_back_url
        )
        if !info or !info.id
          raise "No job id in speechmatics response for task #{self.id}"
        end

        # save the speechmatics job reference
        self.extras['job_id'] = info.id
        # if we previously had an error, zap it
        if self.extras['error'] == "No Speechmatics job_id found"
          self.extras.delete(:error)
        end
        self.status = :working
        self.save!
      end

    rescue Timeout::Error => err

      # it is possible that speechmatics got the request
      # but we failed to get the response.
      # so check back to see if a record exists for our file.
      job_id = self.lookup_sm_job_by_name
      if !job_id
        logger.warn(err)
        puts "Consider cancelling AudioFile #{self.owner.id} as it may be too large to upload."
        # self.cancel!
        raise "No job_id captured for speechmatics job in task #{self.id}"
      end
    rescue => e
      self.extras['error'] = e
      self.save!
      # re-throw original exception
      raise e
    end

  end
  # :nocov:

  # :nocov:
  def lookup_sm_job_by_name

    sm      = Speechmatics::Client.new({ :request => { :timeout => 120 } })
    sm_jobs = sm.user.jobs.list.jobs.first(1000)
    job_id  = nil
    sm_jobs.each do|smjob|
      if smjob['name'] == self.extras['sm_name']
        # yes, it was successful even though SM failed to respond.
        self.extras['job_id'] = job_id = smjob['id']
        self.extras['sm_job_status'] = smjob['job_status']
        if smjob['job_status'] == 'rejected' && smjob['duration'] == 0
          self.extras['error'] = "Speechmatics job empty"
          self.failure
        end
        self.save!
        break
      end
    end
    job_id

  end
  # :nocov:

  def update_premium_transcript_usage(now=DateTime.now)
    billed_user = user
    if !billed_user
      raise "Failed to find billable user with id #{user_id} (#{self.extras.inspect})"
    end

    # call on user.entity so billing goes to org if necessary
    ucalc = UsageCalculator.new(billed_user.entity, now)

    # call on user.entity so billing goes to org if necessary
    billed_duration = ucalc.calculate(MonthlyUsage::PREMIUM_TRANSCRIPTS)

    # call again on the user if user != entity, just to record usage.
    if billed_user.entity != billed_user
      user_ucalc = UsageCalculator.new(billed_user, now)
      user_ucalc.calculate(MonthlyUsage::PREMIUM_TRANSCRIPT_USAGE)
    end

    return billed_duration
  end

  def stuck?
    # cancelled jobs are final.
    return false if status == CANCELLED
    return false if status == COMPLETE

    # in test mode, never stuck
    return false if Rails.env.test?

    # older than max worktime and incomplete
    if outside_work_window?
      return true

    # we failed to register a SM job_id
    elsif !extras['job_id']
      return true

    # process() seems to have failed
    elsif !extras['sm_name']
      return true

    end

    # if we get here, not stuck
    return false
  end

  # :nocov:
  def recover!
    begin
      # easy cases first.
      if !owner
        self.extras['error'] = "No owner/audio_file found"
        failure
        return

      # if we have no sm_name, then we never downloaded in prep for SM job
      elsif !self.extras['sm_name']
        self.process()
        return

      elsif !(self.extras['job_id'] || self.extras['sm_job_id'])
        # try to look it up, one last time
        if !self.lookup_sm_job_by_name
          self.extras['error'] = "No Speechmatics job_id found"
          cancel!
          return
        end
      end

      # call out to SM and find out what our status is
      sm = Speechmatics::Client.new({ :request => { :timeout => 120 } })
      job_id = self.extras['job_id'] || self.extras['sm_job_id']
      sm_job = sm.user.jobs(job_id).get
      self.extras['sm_job_status'] = sm_job.job['job_status']

      # still working?
      if self.extras['sm_job_status'] == 'transcribing'
        logger.warn("Task #{self.id} for Speechmatics job #{job_id} still transcribing")
        return
      end

      # fail any rejected jobs.
      if self.extras['sm_job_status'] == 'rejected' || self.extras['sm_job_status'] == 'deleted'
        self.extras['error'] = "Speechmatics job #{self.extras['sm_job_status']}"
        failure
        return
      end

      # jobs marked 'expired' may still have a transcript. Only the audio is expired from their cache.
      if self.extras['sm_job_status'] == 'expired' or self.extras['sm_job_status'] == 'done'
        finish!
        return
      end

      # if we get here, unknown status, so log and try to finish anyway.
      logger.warn("Task #{self.id} for Speechmatics job #{job_id} has status '#{self.extras['sm_job_status']}'")
      finish!  # attempt to finish. Who knows, we might get lucky.
    rescue => err
      logger.warn("Task #{self.id} #{err}")
      self.extras['error'] = err
      failure
    end
  end
  # :nocov:

  # :nocov:
  def finish_task
    return unless audio_file
    begin
      sm = Speechmatics::Client.new
      # verify job status == done
      self.lookup_sm_job_by_name  unless self.extras['job_id'] || self.extras['sm_job_id']
      job_id = self.extras['job_id'] || self.extras['sm_job_id']
      return unless job_id
      sm_job = sm.user.jobs(job_id).get
      return if sm_job.job['job_status'] == 'transcribing' # not finished yet

      transcript = nil
      transcript = sm_job.transcript

      if duration = sm_job.job['duration']
        self.owner.duration = duration
      end

      if !transcript
        raise "No Speechmatics transcript found"
      end

      new_trans  = process_transcript(transcript)

      # if new transcript resulted, then call analyze
      if new_trans
        audio_file.analyze_transcript
        # make sure there's a subscription_plan_id, so it gets counted toward total.
        if !new_trans.subscription_plan_id
          new_trans.subscription_plan_id = self.owner.user.billable_subscription_plan_id
          new_trans.save!
        end

        # show usage immediately
        update_premium_transcript_usage

        # create audit xref
        self.extras[:transcript_id] = new_trans.id

        # if we previously had an error, zap it
        if self.extras['error']
          self.extras.delete(:error)
        end

        self.save!

        # share the glad tidings
        notify_user
      end
    rescue Faraday::TimeoutError => err
      logger.warn "Faraday::TimeoutError: task: #{task_id}, err: #{err.message}"
      self.extras["error"]=err
      self.failure
    rescue => err
      # if SM throws an error (e.g. 404) we just warn and return
      # since we can't proceed.
      # TODO is this too soft? should we examine and/or re-throw?
      logger.warn(err)
      return
    end
  end
  # :nocov:

  def transcribe_status
    sm = Speechmatics::Client.new
    # verify job status == done
    self.lookup_sm_job_by_name  unless self.extras['job_id'] || self.extras['sm_job_id']
    job_id = self.extras['job_id'] || self.extras['sm_job_id']
    return nil unless job_id
    sm_job = sm.user.jobs(job_id).get
    return sm_job.job['job_status']
  end

  def process_transcript(response)
    trans = nil
    return trans if response.blank? || response.body.blank?

    json = response.body.to_json
    identifier = Digest::MD5.hexdigest(json)

    if trans = audio_file.transcripts.where(identifier: identifier).first
      logger.debug "transcript #{trans.id} already exists for this json: #{json[0,50]}"
      return trans
    end

    transcriber = Transcriber.find_by_name('speechmatics')

    # if this was an ondemand transcript, the cost is retail, not wholesale.
    # 'wholesale' is the cost PUA pays, and translates to zero to the customer under their plan.
    # 'retail' is the cost the customer pays, if the transcript is on-demand.
    cost_type = Transcript::WHOLESALE
    if self.extras['ondemand']
      cost_type = Transcript::RETAIL
    end

    Transcript.transaction do
      trans    = audio_file.transcripts.create!(
        language: 'en-US',  # TODO get this from audio_file?
        identifier: identifier,
        start_time: 0,
        end_time: 0,
        transcriber_id: transcriber.id,
        cost_per_min: transcriber.cost_per_min,
        retail_cost_per_min: transcriber.retail_cost_per_min,
        cost_type: cost_type,
        subscription_plan_id: audio_file.user.billable_subscription_plan_id,
      )
      speakers = response.speakers
      words    = response.words

      speaker_lookup = create_speakers(trans, speakers)

      # iterate through the words and speakers
      tt = nil
      speaker_idx = 0
      prev_speaker = 1
      words.each do |row|
        speaker = speakers[speaker_idx]
        row_end = BigDecimal.new(row['time'].to_s) + BigDecimal.new(row['duration'].to_s)
        speaker_end = speaker ? (BigDecimal.new(speaker['time'].to_s) + BigDecimal.new(speaker['duration'].to_s)) : row_end
        if tt
          if row['name'] == "."
            # always keep punctuation with the word it follows
            tt[:end_time] = row_end
            tt[:text] += row['name']
          else
            if (row_end > speaker_end)
              tt.save
              speaker_idx += 1
              speaker = speakers[speaker_idx] ? speakers[speaker_idx] : speakers[prev_speaker]
              tt = nil
            elsif (row_end - tt[:start_time]) > 5.0
              tt.save
              tt = nil
            else
              tt[:end_time] = row_end
              space = (row['name'] =~ /^[[:punct:]]/) ? '' : ' '
              tt[:text] += "#{space}#{row['name']}"
            end
          end
        end

        if !tt
          tt = trans.timed_texts.build({
            start_time: BigDecimal.new(row['time'].to_s),
            end_time:   row_end,
            text:       row['name'],
            speaker_id: speaker ? speaker_lookup[speaker['name']].id : prev_speaker,
          })
          prev_speaker = tt.speaker_id
        end

      end

      trans.save!
    end
    trans
  end

  def create_speakers(trans, speakers)
    speakers_lookup = {}
    speakers_by_name = speakers.inject({}) {|all, s| all.key?(s['name']) ? all[s['name']] << s : all[s['name']] = [s]; all }
    speakers_by_name.keys.each do |n|
      times = speakers_by_name[n].collect{|r| [BigDecimal.new(r['time'].to_s), (BigDecimal.new(r['time'].to_s) + BigDecimal.new(r['duration'].to_s))] }
      speakers_lookup[n] = trans.speakers.create(name: n, times: times)
    end
    speakers_lookup
  end

  def set_speechmatics_defaults
    extras['public_id']     = SecureRandom.hex(8)
    extras['call_back_url'] = speechmatics_call_back_url
    extras['entity_id']     = user.entity.id if user
    # extras['duration']      = audio_file.duration.to_i if audio_file
  end

  def speechmatics_call_back_url
    Routes.speechmatics_callback_url(model_name: 'task', model_id: self.extras['public_id'])
  end

  # :nocov:
  def download_audio_file
    connection = Fog::Storage.new(StorageConfiguration.popup_storage.credentials)
    uri        = URI.parse(audio_file_url)
    Utils.download_file(connection, uri)
  end
  # :nocov:

  def audio_file_url
    audio_file.public_url(extension: :mp3)
  end

  # :nocov:
  def notify_user
    return unless (user && audio_file && audio_file.item)
    return if extras['notify_sent'] || (ENV["DO_NOT_EMAIL"].include? user.id.to_s)
    return if self.owner.transcripts.count > 1
    if audio_file.item.extra.has_key? 'callback'
      CallbackWorker.perform_async(audio_file.item_id, audio_file.id, audio_file.item.extra['callback']) unless Rails.env.test?
    end
    r = TranscriptCompleteMailer.new_auto_transcript(user, audio_file, audio_file.item).deliver_now
    self.extras['notify_sent'] = DateTime.now.to_s
    self.save!
    r
  end
  # :nocov:

  def audio_file
    owner
  end

  def user
    User.find(user_id) if (user_id.to_i > 0)
  end

  def user_id
    self.extras['user_id']
  end

  def duration
    self.extras['duration'].to_i
  end

  # this method appears to be unused
  # :nocov:
  def usage_duration
    # if parent audio_file gets its duration updated after the task was created, for any reason, prefer it
    if duration and duration > 0
      duration
    elsif !audio_file.duration.nil?
      self.extras['duration'] = audio_file.duration.to_s
      audio_file.duration
    else
      duration
    end
  end
  # :nocov:

end
