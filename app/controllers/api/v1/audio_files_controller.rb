require "digest/sha1"

class Api::V1::AudioFilesController < Api::V1::BaseController
  include ActionView::Helpers::NumberHelper
  include Api::BaseHelper

  expose :item
  expose :audio_files, ancestor: :item
  expose :audio_file
  expose :upload_to_storage
  expose :task

  def index
    respond_with :api, audio_files
  end 

  def update
    if params[:task].present?
      audio_file.update_from_fixer(params[:task])
    else
      audio_file.update_attributes(params[:audio_file])
    end
    respond_with :api, audio_file.item, audio_file
  end

  def create
    if params[:file]
      audio_file.file = params[:file]
    end
    audio_file.user = current_user
    audio_file.save
    respond_with :api, audio_file.item, audio_file
  end

  def show
    # respond w/json only if explicitly asked.
    # otherwise, redirect to physical asset.
    # because of how our routing is configured, everything defaults to 'json'
    # so we have to examine the original request URL to discover
    # if .json was actually present on the request.
    req_format_was_json = request.fullpath.match(/(\.json)$/)
    if req_format_was_json
      respond_with :api, audio_file
    else
      redirect_to audio_file.url
    end
  end

  def destroy
    audio_file.destroy
    respond_with :api, audio_file
  end

  def transcript_text
    response.headers['Content-Disposition'] = 'attachment'
    render text: audio_file.transcript_text, content_type: 'text/plain'
  end

  def premium_transcript_cost
    cost = audio_file.premium_retail_cost
    render status: 200, json: {
      id: audio_file.id,
      type: 'premium',
      filename: audio_file.filename,
      duration: audio_file.duration,
      duration_hms: format_time( audio_file.duration ),
      cost: number_to_currency(cost)
    }
  end

  def order_premium_transcript
    authorize! :order_premium_transcript, audio_file
    logger.debug "order_premium_transcript for audio_file: #{audio_file.inspect}"
    task = audio_file.order_premium_transcript(current_user)
    render status: 202, json: {
      task: task.id,
      status: task.status,
      type: 'premium',
      id: audio_file.id
    }
  end

  # :nocov:
  def order_transcript
    authorize! :order_transcript, audio_file
    
    # make call to amara to create the video
    logger.debug "order_transcript for audio_file: #{audio_file}"
    self.task = audio_file.order_transcript(current_user)
    respond_with :api
  end

  def add_to_amara
    authorize! :add_to_amara, audio_file

    # make call to amara to create the video
    logger.debug "add_to_amara audio_file: #{audio_file}"
    self.task = audio_file.add_to_amara(current_user)
    respond_with :api
  end
  # :nocov:

  def upload_to
    respond_with :api
  end

  # def latest_task
  #   audio_file.tasks.last
  # end

  def upload_to_storage
    audio_file.upload_to
  end

  def listens 
    AudioFile.increment_counter(:listens, params[:audio_file_id])
    render status: 200, json: {status: 'OK'}
  end  
  # these are for the request signing
  # really need to see if this is an AWS or IA item/collection
  # and depending on that, use a specific bucket/key
  include S3UploadHandler

  def bucket
    storage[:bucket]
  end

  def secret
    storage[:secret]
  end

  def storage
    upload_to_storage
  end

  def init_signature
    result = nil

    if task = audio_file.tasks.incomplete.upload.where(identifier: upload_identifier).first
      result = task.extras
    else
      extras = {
        'user_id'       => current_user.id,
        'filename'      => params[:filename],
        'filesize'      => params[:filesize].to_i,
        'last_modified' => params[:last_modified],
        'key'           => params[:key]
      }
      task = audio_file.tasks << Tasks::UploadTask.new(extras: extras)
      result = signature_hash(:init)
    end

    render json: result
  end


  def all_signatures
    task = audio_file.tasks.incomplete.upload.where(identifier: upload_identifier).first
    raise "No Task found for id:#{upload_identifier}, #{params}" unless task

    task.extras['num_chunks'] = params['num_chunks'].to_i
    task.extras['upload_id'] = params['upload_id']
    task.status = Task::WORKING
    task.save!

    ash = all_signatures_hash

    render json: ash
  end

  def chunk_loaded
    result = {}

    if task = audio_file.tasks.incomplete.upload.where(identifier: upload_identifier).first
      task.add_chunk!(params[:chunk])
      result = task.extras
    end

    render json: result
  end

  def upload_finished
    result = {}

    if task = audio_file.tasks.incomplete.upload.where(identifier: upload_identifier).first
      FinishTaskWorker.perform_async(task.id) unless Rails.env.test?
      result = task.extras
    end

    render json: result
  end

  def head_check
    url = params[:url]
    head = HTTParty.head(url, :method => "JSONP")
    type = head["content-type"] || head.headers["content-type"] || "unknown"
    render json: {"content-type" => type}
  end

  protected

  def upload_identifier(options=nil)
    o = options || {
      user_id:       current_user.id,
      filename:      params[:filename],
      filesize:      params[:filesize],
      last_modified: params[:last_modified]
    }
    Tasks::UploadTask.make_identifier(o)
  end

end
