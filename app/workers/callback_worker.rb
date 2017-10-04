require 'utils'

class CallbackWorker
  include Sidekiq::Worker

  sidekiq_options :retry => 25, backtrace: true

  def perform(item_id, audio_file_id, callback_url)
    # POST to the callback_url with our data struct.
    # if we get a 2xx response, consider ourselves finished.
    # otherwise, raise an exception so we can try again.
    item = Item.find item_id
    audio = AudioFile.find audio_file_id
    agent = Utils::new_connection(callback_url)
    payload = {
      item_id: item_id,
      item_extra: item.extra,
      audio_file_id: audio_file_id,
      duration: audio.duration,
      transcript_url: audio.transcript_url,
      status: audio.current_status,
    }.to_json
    response = agent.post(:body => payload, :headers => { "Content-Type" => "application/json" })
    if response.status.to_s.start_with?('2')
      response.status
    else
      raise "Non-2xx response from #{callback_url}: #{response.inspect}"
    end
  end

end
