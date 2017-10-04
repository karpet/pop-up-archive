require 'elasticsearch/model'
require 'ansi'

es_url = 'http://localhost:9200'
if ENV['BONSAI_URL'] || ENV['ELASTICSEARCH_URL']
  es_url = ENV['BONSAI_URL'] || ENV['ELASTICSEARCH_URL']
end

if Rails.env.test?
  es_url = "http://localhost:#{(ENV['TEST_CLUSTER_PORT'] || 9250)}"
end

# make sure we set all ENV the same, for backcompat with
# Tire-based code.
ENV['BONSAI_URL'] = es_url
ENV['ELASTICSEARCH_URL'] = es_url

es_args = {
  url: es_url,
  transport_options: {
    request: {
      timeout: 1800,
      open_timeout: 1800,
    }
  },
  retry_on_failure: 5,
}

if ENV['ES_DEBUG'].to_i > 0
  logger = Logger.new(STDOUT)
  logger.level = Logger::DEBUG
  tracer = Logger.new(STDERR)
  tracer.formatter = lambda { |s, d, p, m| "#{m.gsub(/^.*$/) { |n| '   ' + n }.ansi(:faint)}\n" }
  es_args[:log] = true
  es_args[:logger] = logger
  es_args[:tracer] = tracer
  puts "[#{Time.now.utc.iso8601}] Elasticsearch logging set to DEBUG mode"
end

Elasticsearch::Model.client = Elasticsearch::Client.new(es_args)

ENV['ES_DEBUG'] and puts "[#{Time.now.utc.iso8601}] Using Elasticsearch server #{es_url}"
