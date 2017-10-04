class Item < ActiveRecord::Base

  acts_as_paranoid

  include Searchable

  index_name { Rails.env.test? ? "test_items" : ENV['ITEMS_INDEX_NAME'] || 'items'}

  DEFAULT_INDEX_PARAMS = {except: [:transcription, :rights, :storage_id, :token, :geolocation_id, :csv_import_id, :deleted_at]}

  STANDARD_ROLES = ['producer', 'interviewer', 'interviewee', 'creator', 'host', 'guest']

  SEARCH_RESULTS_PER_PAGE = 20

  settings index: {
    number_of_shards: 2,
    number_of_replicas: 1,
    analysis: {
      analyzer: {
        caseinsensitive: {
          tokenizer: 'keyword',
          filter: ['lowercase']
        }
      }
    },
  } do
    mappings dynamic: 'false' do
      indexes :id,                    type: 'integer', index: :not_analyzed
      indexes :is_public,             type: 'boolean', index: :not_analyzed
      indexes :collection_id,         type: 'integer', index: :not_analyzed
      indexes :collection_title,      type: 'keyword', index: 'not_analyzed'
      indexes :date_created,          type: 'date',   include_in_all: false
      indexes :date_broadcast,        type: 'date',   include_in_all: false
      indexes :created_at,            type: 'date',   include_in_all: false, copy_to: 'date_added'
      indexes :description,           type: 'text'
      indexes :identifier,            type: 'keyword'
      indexes :title,                 type: 'text'
      indexes :title_sort,            type: 'keyword', index: 'not_analyzed'
      indexes :tags,                  type: 'keyword', store: 'yes'
      indexes :contributors,          type: 'keyword',  copy_to: 'contributor'
      indexes :physical_location,     type: 'text'

      indexes :transcripts do
        indexes :audio_file_id,       type: 'integer', index: 'not_analyzed'
        indexes :start_time,          type: 'double', index: 'not_analyzed'
        indexes :confidence,          type: 'float', index: 'not_analyzed'
        indexes :transcript,          type: 'text', store: true
      end

      indexes :audio_files do
        indexes :id,                  type: 'integer', index: :not_analyzed
        indexes :url,                 type: 'text', index: :not_analyzed
        indexes :filename,            type: 'keyword', index: :not_analyzed
        indexes :duration,            type: 'text', index: :not_analyzed
      end

      indexes :image_files do
        indexes :filename,            type: 'text', index: :not_analyzed
        indexes :upload_id,           type: 'keyword', index: :not_analyzed
        indexes :original_file_url,   type: 'text', index: :not_analyzed
        indexes :url do
          indexes :full,              type: 'text', index: :not_analyzed
          indexes :thumb,             type: 'text', index: :not_analyzed
        end
      end

      indexes :duration,              type: 'integer'
      indexes :location do
        indexes :name,                type: 'text'
        indexes :position,            type: 'geo_point'
      end

      indexes :entities do
        indexes :entity,              type: 'keyword', store: 'yes'
        indexes :category,            type: 'keyword'
      end

      STANDARD_ROLES.each do |role|
        indexes role.pluralize.to_sym, type: 'keyword', copy_to: role, index: 'not_analyzed'
      end
    end
  end

  before_validation :set_defaults, if: :new_record?

  before_update :handle_collection_change, if: :collection_id_changed?
  after_update  :do_after_update
  after_destroy :remove_from_index unless Rails.env.test?

  attr_accessible :date_broadcast, :date_created, :date_peg,
    :description, :digital_format, :digital_location, :duration,
    :episode_title, :extra, :identifier, :music_sound_used, :notes,
    :physical_format, :physical_location, :rights, :series_title,
    :tags, :title, :transcription, :adopt_to_collection, :language,
    :image, :remote_image_url, :image_files, :transcript_type, :id

  belongs_to :geolocation
  belongs_to :csv_import
  belongs_to :storage_configuration, class_name: "StorageConfiguration", foreign_key: :storage_id
  belongs_to :collection, -> { with_deleted }

  has_many   :collection_grants, through: :collection
  has_many   :users, through: :collection_grants

  has_many   :instances, dependent: :destroy
  has_many   :audio_files, dependent: :destroy
  has_many   :transcripts, through: :audio_files
  has_many   :image_files, :as => :imageable, dependent: :destroy

  has_many   :contributions, dependent: :destroy
  has_many   :contributors, through: :contributions, source: :person

  has_many   :entities, dependent: :destroy
  has_many   :confirmed_entities, -> { where is_confirmed: true }, class_name: 'Entity'
  has_many   :unconfirmed_entities, -> { where Entity.arel_table[:is_confirmed].eq(nil).or(Entity.arel_table[:is_confirmed].eq(false)) }, class_name: 'Entity'
  has_many   :high_scoring_entities, -> { where Entity.arel_table[:is_confirmed].eq(nil).or(Entity.arel_table[:is_confirmed].eq(false)).and(Entity.arel_table[:score].gteq(0.95)) }, class_name: 'Entity'
  has_many   :middle_scoring_entities, -> { where Entity.arel_table[:is_confirmed].eq(nil).or(Entity.arel_table[:is_confirmed].eq(false)).and(Entity.arel_table[:score].gt(0.75).and(Entity.arel_table[:score].lt(0.95))) }, class_name: 'Entity'
  has_many   :low_scoring_entities, -> { where Entity.arel_table[:is_confirmed].eq(nil).or(Entity.arel_table[:is_confirmed].eq(false)).and(Entity.arel_table[:score].lteq(0.75).or(Entity.arel_table[:score].eq(nil))) }, class_name: 'Entity'

  STANDARD_ROLES.each do |role|
    has_many "#{role}_contributions".to_sym, -> { where role: role }, class_name: "Contribution"
    has_many role.pluralize.to_sym, through: "#{role}_contributions".to_sym, source: :person
  end

  scope :publicly_visible, -> { where(is_public: true) }

  delegate :title, to: :collection, prefix: true

  # TODO fix this for Rails 4
  #accepts_nested_attributes_for :contributions

  def duration
    read_attribute(:duration) || audio_files.inject(0){|s,a| s + a.duration.to_i}
  end

  def token
    read_attribute(:token) || update_token
  end

  def url
    "#{Routes.root_url}collections/#{collection_id}/items/#{id}"
  end

  def do_after_update
    # a little hack since Item is updated immediately after upload but before there is anything to render
    if updated_at - created_at > 10
      prerender_cache
    end
  end

  def remove_from_index
    self.__elasticsearch__.delete_document
  end

  def prerender_cache
    if is_public and Rails.env.production?
      PrerenderCacheWorker.perform_async(self.id)
    end
  end

  @@instance_lock = Mutex.new
  def update_token
    @@instance_lock.synchronize do
      begin
        t = "#{hosterize((self.title||'untitled')[0,50])}." + generate_token(6) + ".popuparchive.org"
      end while Item.where(:token => t).exists?
      self.update_attribute(:token, t)
      t
    end
  end

  def generate_token(length=10)
    cs = ('A'..'Z').to_a + ('a'..'z').to_a + ('0'..'9').to_a
    SecureRandom.random_bytes(length).each_char.map{|c| cs[(c.ord % cs.length)]}.join
  end

  # like parameterize, but no '_'
  def hosterize(string, sep = '-')
    # replace accented chars with their ascii equivalents
    parameterized_string = ActiveSupport::Inflector.transliterate(string).downcase
    # Turn unwanted chars into the separator
    parameterized_string.gsub!(/[^a-z0-9\-]+/, sep)
    unless sep.nil? || sep.empty?
      re_sep = Regexp.escape(sep)
      # No more than one of the separator in a row.
      parameterized_string.gsub!(/#{re_sep}{2,}/, sep)
      # Remove leading/trailing separator.
      parameterized_string.gsub!(/^#{re_sep}|#{re_sep}$/, '')
    end
    parameterized_string
  end

  def upload_to
    storage.direct_upload? ? storage : collection.upload_to
  end

  def get_storage
    collection.try(:default_storage)
  end

  def storage
    storage_configuration || collection.try(:default_storage)
  end

  def geographic_location=(name)
    self.geolocation = Geolocation.for_name(name)
  end

  def geographic_location
    geolocation.name
  end

  def creator=(creator)
    self.creators = [creator]
  end

  def creator
    self.creators.try(:first)
  end

  def transcription
    transcript_text || super
  end

  def transcript_text
    audio_files.collect{|af| af.transcript_text}.join("\n")
  end

  def collection_title
    collection.try(:title)
  end

  def to_indexed_json(params={})
    as_indexed_json(params).to_json
  end

  def as_indexed_json(params={})
    as_json(params.reverse_merge(DEFAULT_INDEX_PARAMS)).tap do |json|
      ([:contributors] + STANDARD_ROLES.collect{|r| r.pluralize.to_sym}).each do |assoc|
        json[assoc]      = send(assoc).map{|c| c.as_json }
      end
      json[:title_sort]  = title_for_index_sort
      json[:audio_files] = audio_for_index
      json[:image_files] = images_for_index
      json[:tags]        = tags_for_index
      json[:location]    = geolocation.as_indexed_json if geolocation.present?
      json[:transcripts] = transcripts_for_index
      json[:entities] = entities.map(&:as_indexed_json)
      json[:collection_title] = collection.title if collection.present?
      json[:confirmed_entities] = confirmed_entities.map(&:as_indexed_json)
      json[:low_unconfirmed_entities] = low_scoring_entities.map(&:as_indexed_json)
      json[:mid_unconfirmed_entities] = middle_scoring_entities.map(&:as_indexed_json)
      json[:high_unconfirmed_entities] = high_scoring_entities.map(&:as_indexed_json)
      json[:date_created]   = self.date_created.nil? ? nil : self.date_created.as_json
      json[:date_broadcast] = self.date_broadcast.nil? ? nil : self.date_broadcast.as_json
      json[:date_added]     = self.created_at.as_json
    end
  end

  def title_for_index_sort
    return '' if self.title.nil?
    ttl = self.title.strip.downcase
    # remove any non alphanumerics (mostly for leading quotes etc)
    ttl.gsub!(/[^\p{Word}]+/, '')
    # only the first 16 chars to conserve some space and memory at sort time
    ttl[0,16]
  end

  def audio_for_index
    hashed = []
    audio_files.each do |af|
      hashed.push({
        :id       => af.id,
        :url      => af.player_url,
        :filename => af.filename,
        :duration => af.duration_hms,
      })
    end
    hashed
  end

  def images_for_index
    hashed = []
    imgfs =  []
    if image_files and image_files.size > 0
      imgfs = image_files
    elsif collection and collection.image_files and collection.image_files.size > 0
      imgfs = collection.image_files
    end
    imgfs.each do |imgf|
      hashed.push({
        :filename => imgf.filename,
        :url => imgf.urls,
        :upload_id => imgf.upload_id,
        :original_file_url => imgf.original_file_url,
      })
    end
    hashed
  end

  def tags
    super || self.tags = []
  end

  def adopt_to_collection=(collection_id)
    self.collection_id = collection_id
  end

  def set_defaults
    if is_public.nil?
      self.is_public = (collection.present? && collection.items_visible_by_default)
    end
    if storage_id.nil?
      self.storage_id = (collection.present? ? collection.default_storage_id : nil)
    end
    true
  end

  def handle_collection_change

    # if there is no change in collection id, no need to change
    return true unless (collection_id_was && collection_id)

    # get a handle on current and past collections
    collection_was = Collection.find(collection_id_was)
    collection_is  = Collection.find(collection_id)

    # set the item visibility to that of the new collection
    self.is_public = collection_is.items_visible_by_default

    # if this is the same storage bucket and provider, then flipping is_public (above)
    # is all we are required to do.
    return true if (self.storage == collection_is.default_storage)

    # if we get here, then move the associated assets too.

    # move each audio file to new collection storage
    self.audio_files.each do |af|
      if af.storage_configuration

        # af already stored in the right place? nothing to do.
        if af.storage_configuration == collection_is.default_storage

        # af NOT stored in the right place? move it to the correct storage for this item
        else
          af.copy_to_item_storage
        end
      else
        # no storage defined at the audio file level; af should be at collection_was storage
        # updating af triggers af.process_update_file -> copy_to_item_storage, so don't explictly call it here
        # logger.debug "af #{af.id} has no storage, set to was: #{collection_was.default_storage.inspect}"
        af.update_attributes({storage_configuration: collection_was.default_storage, storage_id: collection_was.default_storage_id}, without_protection: true)
      end
    end
    true
  end

  def is_premium?
    self.transcript_type == "premium"
  end

  def image_url
    if image
      image.public_url
    elsif image_files and image_files.size > 0
      image_files.first.public_url
    elsif collection and collection.image_files and collection.image_files.size > 0
      collection.image_files.first.public_url
    else
      nil
    end
  end

  def image_thumb
    if image_files and image_files.size > 0
      image_files.first.urls[:thumb][0]
    elsif collection and collection.image_files and collection.image_files.size > 0
      collection.image_files.first.urls[:thumb][0]
    else
      nil
    end
  end

  private

  def tags_for_index
    tags.dup.tap do |tfi|
      tags.each do |tag|
        parts = tag.split('/')
        1.upto(parts.size-1) do |number|
          tfi.push(parts[0...number].join('/'))
        end
      end
    end.sort.uniq
  end

  def transcripts_for_index
    begin
      trans=audio_files.map(&:best_transcript).compact
      trans.flatten.map(&:timed_texts).flatten.map(&:as_indexed_json)
    rescue => err
      puts "Item #{id}: #{err}"
    end
  end
end
