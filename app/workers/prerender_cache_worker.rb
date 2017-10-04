# encoding: utf-8

class PrerenderCacheWorker
  include Sidekiq::Worker

  sidekiq_options :retry => 25, :backtrace => true

  def perform(item_id)
    ActiveRecord::Base.connection_pool.with_connection do
      item = Item.find item_id.to_i
      response = HTTParty.post("https://api.prerender.io/recache",
        body: { prerenderToken: ENV["PRERENDER_TOKEN"], url: item.url }
      )
      if response.success?
        #response # nothing todo
      else
        raise response.response
      end
      true # success
    end
  end

end
