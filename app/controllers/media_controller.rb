require 'digest/md5'

class MediaController < ApplicationController

  # 'show' will validate tokenized-url and redirect to real storage url, with expiration.
  def show
    version = nil
    asset = params[:class].camelize.constantize.find(params[:id])
    if asset.public_url_token_valid?(params[:token], params)
      version = params[:extension] ? params[:extension].to_sym : nil
      if params[:use] and params[:use] == "thumb"
        url = asset.file.thumb.url
      else 
        url = asset.url(version)
      end
      redirect_to url
    else
      head 401
    end
  end

  # 'permanent' will always redirect to tokenized url (handled by 'show')
  def permanent
    asset = params[:class].camelize.constantize.find(params[:idhex].to_i(16))
    version = params[:extension] ? params[:extension].to_sym : nil
    url = asset.public_url({:extension => version})
    redirect_to url
  end 

end
