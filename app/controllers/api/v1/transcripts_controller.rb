class Api::V1::TranscriptsController < Api::V1::BaseController
  expose :item
  expose :audio_files, ancestor: :item
  expose :audio_file
  expose(:transcript) {
    if params[:audio_file_id]
      audio_file.best_transcript
    else
      Transcript.find params[:id]
    end
  }

  respond_to :xml, :srt, :txt, :json, :vtt

  def show
    if params[:audio_file_id]
      attachment_name = "#{transcript.audio_file.filename}.transcript.#{params[:format]}"
      send_data render_to_string,
        disposition: %(attachment; filename="#{attachment_name}"),
        content_type: 'text/plain'
    else
      respond_with :api, transcript
    end
  end
end
