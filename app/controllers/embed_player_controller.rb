class EmbedPlayerController < ApplicationController
  def show
    @name=params[:name]
    @file_id=params[:file_id]
    @item_id=params[:item_id]
    @collection_id=params[:collection_id]
    @mp3 = AudioFile.find(params[:file_id]).public_url(extension: :mp3)
    @ogg = AudioFile.find(params[:file_id]).public_url(extension: :ogg)
  end

  # embedable player with transcript
  def tplayer
    @embed      = params[:embed] ? true : false
    @file_id    = params[:file_id]
    @audio_file = AudioFile.find(@file_id)
    may_read    = true
    if !@audio_file.item.is_public
      logger.warn("private item");
      if current_user
        ability = Ability.new(current_user)
        if !ability.can?(:read, @audio_file.item)
          logger.warn("current_user may not read")
          may_read = false
        end
      else
        logger.warn("no current_user")
        may_read = false
      end
    end
    if !may_read
      respond_to do |format|
        format.html {
          render :formats => [:html], :file => File.join(Rails.root, 'public', '403'), :status => 403
        }
        format.json {
          render :text => { :error => "permission denied", :status => 403 }.to_json, :status => 403
        }
      end
      return
    end
    @mp3        = @audio_file.url(:mp3)
    @ogg        = @audio_file.url(:ogg)
    @transcript = @audio_file.best_transcript
    @title      = params[:title] || @audio_file.item.title
    @chunk_size = params[:chunk] || 30
    @start      = params[:start] || 0
    @end        = params[:end]   || false

    respond_to do |format|
      format.html {
        render :formats => [:html]
      }
      format.json {
        render :json => {
          file_id: @file_id,
          mp3:     @mp3,
          ogg:     @ogg,
          title:   @title,
          start:   @start,
          end:     @end
        }.to_json, :callback => params[:callback]
      }
    end
  end

  def iframe
    @file_id    = params[:file_id]
  end

end
