class Api::V1::SpeakersController < Api::V1::BaseController
  expose :speaker

  def update
    speaker.save
    respond_with :api, speaker
  end

  def destroy
    speaker.destroy
    respond_with :api, speaker
  end

end