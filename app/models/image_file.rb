class ImageFile < ActiveRecord::Base

  include PublicAsset
  include FileStorage

  attr_accessible :file, :original_file_url, :storage_id, :is_uploaded, :remote_file_url, :imageable_id, :imageable_type
  belongs_to :imageable, :polymorphic => true
  belongs_to :storage_configuration, class_name: "StorageConfiguration", foreign_key: :storage_id

  mount_uploader :file, ImageUploader

  after_commit :process_file, on: :create
  after_commit :process_update_file, on: :update

  def process_update_file
    # logger.debug "af #{id} call copy_to_item_storage"
    copy_to_item_storage
  end

  def detect_urls
    ImageUploader.version_formats.keys.inject({}){|h, k| h[k] = { url: file.send(k).url, detected_at: nil }; h}
  end

  def process_file
    # don't process file if no file to process yet (s3 upload)
    return if !has_file? && original_file_url.blank?

    copy_original

  rescue Exception => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
  end

  # returns hash of array of urls for each derivative
  def urls
    {
      :full  => [ public_url ],
      :thumb => [ public_url({:use => 'thumb'}) ],
    }
  end

  def save_thumb_version
    file.recreate_versions!
    logger.info "****************** created  thumb version" 
  end
   
  def file_uploaded(file_name)
    update_attributes(:is_uploaded => true, :file => file_name)
    upload_id = upload_to.id
    update_file!(file_name, upload_id)
    # now copy it to the right place if it needs to be (e.g. s3 -> ia)
    # or if it is in the right spot, process it!
    copy_to_item_storage
    save_thumb_version
    # logger.debug "Tasks::UploadTask: after_tr       
  end

  def is_collection_image?
    self.imageable.is_a?(Collection)
  end

  def item
    self.imageable
  end

  def collection
    if is_collection_image?
      self.imageable
    else
      self.item.try(:collection)
    end 
  end

  def get_storage
    if is_collection_image?
      self.imageable.default_storage
    else
      storage_configuration || imageable.try(:storage)
    end
  end

  def item_storage
    if is_collection_image?
      collection.default_storage
    else
      item.storage
    end
  end

  def storage_id 
    if is_collection_image?
      self.imageable.default_storage.id
    else
      storage.id
    end
  end

  def get_token
    if is_collection_image?
      collection.token
    else
      item.token
    end
  end

  def collection_title
    is_collection_image? ? collection.try(:title) : item.try(:collection).try(:title)
  end

end
