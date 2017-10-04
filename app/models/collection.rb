class Collection < ActiveRecord::Base
  resourcify :is_resource_of

  acts_as_paranoid

  # include ActiveModel::ForbiddenAttributesProtection
  attr_accessible :title, :description, :items_visible_by_default, :copy_media, :creator, :creator_id, :storage, :default_storage_id

  belongs_to :default_storage, class_name: "StorageConfiguration"
  belongs_to :upload_storage, class_name: "StorageConfiguration"
  belongs_to :creator, class_name: "User"

  has_many :collection_grants, dependent: :destroy
  #has_many :users, through: :collection_grants # TODO this is broken
  has_many :items, dependent: :destroy
  has_many :audio_files, through: :items
  has_many :transcripts, through: :audio_files
  has_many :image_files, :as => :imageable, dependent: :destroy

  validates_presence_of :title

  validate :validate_storage

  scope :is_public, -> { where(items_visible_by_default: true) }

  before_validation :set_defaults

  after_commit :after_create_hooks, on: :create
  after_commit :after_update_hooks, on: :update

  def after_create_hooks
    grant_to_creator
    check_billable_to!
  end

  def after_update_hooks
    check_billable_to!
  end

  def check_billable_to!
    begin
      billable_to
    rescue Exception => err
      Rails.logger.error(err)
    end
  end

  def billable_to
    return @_billable_to if @_billable_to

    # find the first owner via roles.
    # croak if there is more than one.
    owner_role = get_owner_role
    if !owner_role
      # create one
      # if the creator has an organization, the org owns the collection
      if creator
        if creator.is_a?(User)
          if creator.organization
            owner = creator.organization
          else
            owner = creator
          end
        else
          owner = creator
        end
      else
      # no creator. prefer any Org granted authz
        grant = collection_grants.where(collector_type: 'Organization').first
        if grant and grant.collector
          owner = grant.collector
        else
          # otherwise, the oldest grantee, if any.
          grant = collection_grants.where('collector_id is not null').order('created_at asc').first
          if grant and grant.collector
            owner = grant.collector.entity
          else
            raise "Collection #{self.id} has no creator and no collection_grants. Poor orphan!"
          end
        end
      end
      # sanity check. make sure we have an owner identified
      if !owner
        raise "Failed to identify an owner for Collection #{self.id}"
      end
      owner.add_role :owner, self
      @_billable_to = owner
    else
      @_billable_to = owner_role.single_designee  # prefers Organization over User
    end

    return @_billable_to
  end

  def get_owner_role
    owner_roles = is_resource_of.where(:name => :owner)
    if owner_roles.size > 1
      raise "More than one owner role defined for collection #{id}"
    end
    return owner_roles.first
  end

  def set_owner(user_or_org)
    begin
      cur_owner = billable_to
      cur_owner_role = get_owner_role
      if cur_owner_role
        cur_owner.remove_role :owner, self
      end
      user_or_org.add_role :owner, self
      user_or_org.save!
      # nullify cache
      @_billable_to = nil
      return user_or_org
    rescue => err
      raise "Failed to set_owner of collection #{self.id} to #{user_or_org.inspect}: #{err}"
    end
  end

  def storage=(provider)
    if (provider == 'InternetArchive') && (!default_storage || (default_storage.provider != 'InternetArchive'))
      self.default_storage = StorageConfiguration.archive_storage
    end
    set_storage
  end

  def storage
    # default_storage.provider
    default_storage
  end

  def validate_storage
    errors.add(:default_storage, "must be set") if !default_storage
    errors.add(:upload_storage, "must be set when default does not allow direct upload") if (!upload_storage && !default_storage.direct_upload?)
  end

  def upload_to
    upload_storage || default_storage
  end

  def set_storage
    self.default_storage = StorageConfiguration.popup_storage if !default_storage
    if default_storage.direct_upload?
      self.upload_storage = nil
    else
      self.upload_storage = StorageConfiguration.popup_storage if !upload_storage
    end
  end

  def set_defaults
    self.set_storage
    self.copy_media = true if self.copy_media.nil?
  end

  def grant_to_creator
    return unless creator
    collector = creator.organization || creator
    collector.collections << self unless creator.collections.include? self
  end

  def used_metered_storage
    @_used_metered_storage ||= (items.map{|item| item.audio_files.where(metered: true).sum(:duration) }.inject(:+) || 0)
  end

  def used_unmetered_storage
    @_used_unmetered_storage ||= (items.map{|item| item.audio_files.where(metered: false).sum(:duration) }.inject(:+) || 0)
  end

  def token
    read_attribute(:token) || update_token
  end

  def url
    "#{Routes.root_url}collections/#{id}"
  end

  def item_ids
    @_item_ids ||= super
  end

  @@instance_lock = Mutex.new
  def update_token
    @@instance_lock.synchronize do
      begin
        t = "#{hosterize((self.title||'untitled')[0,50])}." + generate_token(6) + ".popuparchive.org"
      end while Collection.where(:token => t).exists?
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

  def recent_files
    #require 'benchmark'
    audio_files = []
    files = self.audio_files.includes(:item).last(3)
    files.each do |file|
      #el = Benchmark.realtime {
        #Rails.logger.warn('-'*80)
        audio_file = { file_name: file["file"], item_name: file.item.title, item_id: file.item.id, file_status: file.current_status }
        audio_files << audio_file
        #Rails.logger.warn('='*80)
      #}
      #Rails.logger.warn("Elapsed: #{el}")
    end
    audio_files
  end

end
