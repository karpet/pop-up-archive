class ElasticsearchBulkIndexWorker
  include Sidekiq::Worker
  sidekiq_options retry: 5, queue: 'elasticsearchbulk'

  def perform(model, index_name, ids, opts={})
    if base_url = opts.delete("base_url")
      Routes.default_url_options[:host]=base_url
    end
    klass = model.capitalize.constantize
    if es_url = opts.delete("bonsai_url")
      client = Elasticsearch::Client.new host: es_url
    else
      client = klass.__elasticsearch__.client
    end
    type=klass.__elasticsearch__.document_type
    batch = klass.where(id: ids)
    batch_for_bulk = []
    batch.each do |doc|
      result = { index: { _id: doc.id, data: doc.as_indexed_json } }
      batch_for_bulk.push(result)
    end
    begin
      tries ||= 5
      client.bulk({
       index: index_name,
       type: type,
       body: batch_for_bulk
      })
    rescue Elasticsearch::Transport::Transport::ServerError => err
      puts err
      retry unless (tries -= 1).zero?
    rescue JSON::ParserError => err
      raise "Skipping items: #{batch.first.id} - #{batch.last.id}. #{err}"
    end
  end
end
