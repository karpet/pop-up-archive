require "digest/sha1"

class Tasks::UploadTask < Task

  before_validation :set_upload_task_defaults, :on => :create

  def finish_task
    super
    # logger.debug "Tasks::UploadTask: after_transition: any => :complete start !!!!"

    if self.owner.nil?
      # logger.debug "Tasks::UploadTask: after_transition: any => :complete owner nil"
    else
      # logger.debug "Tasks::UploadTask: after_transition: any => :complete owner update file"
      # set the file on the owner, and the storage as the upload_to
      file_name = File.basename(self.extras['key'])
      upload_id = self.owner.upload_to.id
      
      self.owner.update_file!(file_name, upload_id)
      
      if !destination_exists? && !Rails.env.test? 
        self.cancel! 
        raise "The file has been updated and destination for AudioFile #{self.owner.id} is #{self.owner.destination}" 
      end
      
      # now copy it to the right place if it needs to be (e.g. s3 -> ia)
      # or if it is in the right spot, process it!
      unless self.owner(true).copy_to_item_storage
        self.owner(true).process_file
      end
      # logger.debug "Tasks::UploadTask: after_transition: any => :complete file updates over"
    end

    # logger.debug "Tasks::UploadTask: after_transition: any => :complete finish !!!!"

  rescue Exception => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
  end

  def destination_exists?
    dest_url = URI.parse(self.owner.destination)
    connection = Fog::Storage.new(storage.credentials)
    file_exists?(connection, dest_url)
  end

  def stuck?
    return true if super

    if !self.status_is_final? and self.num_chunks > 0 and self.num_chunks == self.chunks_uploaded.size
      return true
    end

    return false
  end

  def recover!
    if !self.owner
      self.extras['error'] = "No owner"
      self.cancel!
    elsif (self.num_chunks != self.chunks_uploaded.size) && (self.created_at < 1.hour.ago)
      self.extras['error'] = "Incomplete chunks uploaded"
      self.cancel!
    elsif !destination_exists? && stuck? && (self.created_at < 30.minutes.ago)
      self.extras['error'] = 'Destination URL does not exist'
      self.cancel!
    else
      self.finish!
    end
  end

  def set_upload_task_defaults
    self.extras = HashWithIndifferentAccess.new unless extras
    self.extras['chunks_uploaded'] = [].to_csv unless self.extras.key?('chunks_uploaded')
    self.identifier = Tasks::UploadTask.make_identifier(extras) unless identifier
  end

  def num_chunks
    extras['num_chunks'].to_i
  end

  def add_chunk!(chunk)
    self.chunks_uploaded = (chunks_uploaded << chunk.to_i).sort.uniq
    save!
  end

  def chunks_uploaded
    (extras['chunks_uploaded'] || [].to_csv).parse_csv.map(&:to_i)
  end

  def chunks_uploaded=(chunks_array)
    self.extras ||= HashWithIndifferentAccess.new
    self.extras['chunks_uploaded'] = chunks_array.to_csv
  end

  def self.make_identifier(options=nil)
    raise 'you must pass in options to make an identifier' unless options
    o = HashWithIndifferentAccess.new(options)
    Digest::SHA1.hexdigest("u:#{o[:user_id]};n:#{o[:filename]};s:#{o[:filesize]};m:#{o[:last_modified]}")
  end

end
