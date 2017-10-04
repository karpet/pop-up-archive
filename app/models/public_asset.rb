require 'active_support/concern'
require 'digest/md5'

# expects underlying model to have filename, class, and id attributes
module PublicAsset
  extend ActiveSupport::Concern

  # returns "permanent" URL suitable for use when content is being pre-rendered/cached.
  def permanent_public_url(options={})
    opts = set_defaults(options)
    ext  = opts[:extension]
    # 'id' is slightly obfuscated as hexadecimal string
    url = Routes.root_url + ["media",opts[:class],opts[:id].to_i.to_s(16),opts[:name]].join('/')
    url += ".#{ext}" unless ext.blank?
    url
  end

  # validates token with or without expires option
  def public_url_token(options={})
    o = set_defaults(options)

    t = token_secret
    e = o[:expires]
    u = o[:use]
    c = o[:class]
    i = o[:id]
    n = o[:name]
    x = o[:extension]

    str = [t,e,u,c,i,n,x].join("|")
    logger.debug(str)

    Digest::MD5.hexdigest(str)
  end

  # media/:token/:expires/:use/:class/:id/:name.:extension
  def public_url(options={})
    o = set_defaults(options)

    t = public_url_token(o)
    e = o[:expires]
    u = o[:use]
    c = o[:class]
    i = o[:id]
    n = o[:name]
    x = o[:extension]

    url = Routes.root_url + ["media",t,e,u,c,i,n].join("/")
    url = url + ".#{x}" unless x.blank?
    url
  end

  def public_url_token_valid?(token, options={})
    check   = public_url_token(options)
    expires = options[:expires].to_i
    now     = DateTime.now.to_i
    logger.debug("token: #{token}, check: #{check}, expires: #{expires}, now: #{now}")
    token == public_url_token(options) && ((expires == 0) || (expires > now))
  end

  def set_defaults(options)
    o = HashWithIndifferentAccess.new({
      use:       'public',
      class:     self.class.name.demodulize.underscore,
      id:        self.id,
      name:      self.filename_base,
      extension: self.filename_extension
    }).merge(options)
    o[:expires] = o[:expires].to_i
    o
  end

  def filename_base
    fn = self.filename || ''
    # dots in the filename can throw off the routing regex match
    File.basename(fn, File.extname(fn)).gsub(/\./,'-')
  end

  def filename_extension
    fn = self.filename || ''
    ext = File.extname(fn)
    (!ext.blank? && (ext.first == '.')) ? ext[1..-1] : ''
  end

  def token_secret
    ENV['POPUP_MEDIA_SECRET']
  end

end
