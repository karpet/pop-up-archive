class SearchRequestFailed < StandardError; end

class Search

  attr_reader :indices, :types, :query, :facets, :filters, :options, :explain, :script_fields

  def initialize(indices=nil, options={}, &block)
    if indices.is_a?(Hash)
      set_indices_options(indices)
      @indices = indices.keys
    else
      @indices = Array(indices)
    end
    @types   = Array(options.delete(:type)).map { |type| Utils.escape(type) }
    @options = options

    @path    = ['/', @indices.join(','), @types.join(','), '_search'].compact.join('/').squeeze('/')
    block.arity < 1 ? instance_eval(&block) : block.call(self) if block_given?
  end


  def set_indices_options(indices)
    indices.each do |index, index_options|
      if index_options[:boost]
        @indices_boost ||= {}
        @indices_boost[index] = index_options[:boost]
      end
    end
  end

  def results
    @results  || (perform; @results)
  end

  def response
    @response || (perform; @response)
  end

  def json
    @json     || (perform; @json)
  end

  def url
    $stderr.puts "Search.Configuration"
    $stderr.puts pp Configuration
    Configuration.url + @path
  end

  def params
    options = @options.except(:wrapper, :payload, :load)
    options.empty? ? '' : '?' + options.to_param
  end

  def query(&block)
    @query = Query.new
    block.arity < 1 ? @query.instance_eval(&block) : block.call(@query)
    self
  end

  def sort(&block)
    @sort = Sort.new(&block).to_ary
    self
  end

  def facet(name, options={})
    @facets ||= {}
    @facets.update Facet.new(name, options).to_hash
    self
  end

  def facet_agg(name, options={})
    @aggregations ||= {}
    facet = Facet.new(name, options).to_hash
    @aggregations.update(facet)
    self
  end

  def filter(type, *options)
    @filters ||= {}
    @filters[type] = options
    self
  end

  def script_field(name, options={})
    @script_fields ||= {}
    @script_fields.merge! ScriptField.new(name, options).to_hash
    self
  end

  def suggest(name, &block)
    @suggest ||= {}
    raise "Tire no longer active"
    @suggest.update Tire::Suggest::Suggestion.new(name, &block).to_hash
    self
  end

  def highlight(*args)
    unless args.empty?
      @highlight = Highlight.new(*args)
      self
    else
      @highlight
    end
  end

  # def from(value)
  #   @from = value
  #   @options[:from] = value
  #   self
  # end

  def from_for_aggs(value)
    if !value || value <= 1
      @from = 0
    else
      @from = (((value -1) * 20) +1)
    end
  end

  def agg_count(value)
    if value
      @agg_count = value
    else
      @agg_count = 10
    end
  end

  def filter_with_prefix(value)
    @prefix_agg = value if value
  end

  def size(value)
    @size = value
    @options[:size] = value
    self
  end

  def fields(*fields)
    @fields = Array(fields.flatten)
    self
  end

  def partial_field(name, options)
    @partial_fields ||= {}
    @partial_fields[name] = options
  end

  def explain(value)
    @explain = value
    self
  end

  def version(value)
    @version = value
    self
  end

  def min_score(value)
    @min_score = value
    self
  end

  def track_scores(value)
    @track_scores = value
    self
  end

  def perform
  #   @response = Configuration.client.get(self.url + self.params, self.to_json)
  #   if @response.failure?
  #     STDERR.puts "[REQUEST FAILED] #{self.to_curl}\n"
  #     raise SearchRequestFailed, @response.to_s
  #   end
  #   @json     = MultiJson.decode(@response.body)
  #   @results  = Results::Collection.new(@json, @options)
  #   return self
  # ensure
  #   logged
  end

  def to_curl
    to_json_escaped = to_json.gsub("'",'\u0027')
    #%Q|curl -X GET '#{url}#{params.empty? ? '?' : params.to_s + '&'}pretty' -d '#{to_json_escaped}'|
  end

  def to_agg_hash
    @options[:payload] || begin
      request = {}
      request.update( { :indices_boost => @indices_boost } ) if @indices_boost
      aggregations = build_aggs
      request.update( {:aggregations => aggregations.to_hash } ) if aggregations
      request.update( { :sort   => @sort.to_ary   } )    if @sort
      #this has to be set to 20 for size and from dynamic paging from the setResults method in services searches.js.erb
      request.update( {:size => Item::SEARCH_RESULTS_PER_PAGE} )
      request.update( { :highlight => @highlight.to_hash } ) if @highlight
      request.update( { :from => @from } )               if @from
      request.update( { :fields => @fields } )           if @fields
      request.update( { :partial_fields => @partial_fields } ) if @partial_fields
      request.update( { :script_fields => @script_fields } ) if @script_fields
      request.update( { :version => @version } )         if @version
      request.update( { :explain => @explain } )         if @explain
      request.update( { :min_score => @min_score } )     if @min_score
      request.update( { :track_scores => @track_scores } ) if @track_scores
      request
    end
  end

  def build_aggs
    es_query = {}
    @aggregations.each do |agg|
      name = agg[0]
      es_query[name] = {}
      type = get_type(name)
      if agg[1][:terms]
        terms = agg[1][:terms]
      else
        terms = agg[1]
      end
      updated_terms = update_terms(type, terms, name)
      es_query[name] = {type.to_sym => updated_terms}
    end
    es_query
  end

  def get_type(name)
    if name.to_s == "date_created" || name.to_s == "date_broadcast" || name.to_s == "date_added"
      type = "date_histogram"
    elsif name.to_s == "duration"
      type = "histogram"
    else
      type = "terms"
    end
    type
  end

  def update_terms(type, terms, name)
    case type.to_s
    when 'date_histogram'
      terms.update({interval: 'year'})
    when 'histogram'
      terms.update({interval: 60*5})
    when 'terms'
      # terms.update({ all_terms: false})
      terms.update({ size: @agg_count}) if @agg_count
      terms.update({ :include => @prefix_agg, :order => {"_term" => "asc"} }) if @prefix_agg
    else
      # terms.update({ all_terms: false})
    end
    terms.update({ field: name })
    terms
  end

  def to_json(options={})
    payload = to_hash
    # TODO: Remove when deprecated interface is removed
    if payload.is_a?(String)
      payload
    else
      MultiJson.encode(payload, :pretty => Configuration.pretty)
    end
  end

  def logged(endpoint='_search')
    # if Configuration.logger

    #   Configuration.logger.log_request endpoint, indices, to_curl

    #   took = @json['took']  rescue nil
    #   code = @response.code rescue nil

    #   if Configuration.logger.level.to_s == 'debug'
    #     body = if @json
    #       MultiJson.encode( @json, :pretty => Configuration.pretty)
    #     else
    #       MultiJson.encode( MultiJson.load(@response.body), :pretty => Configuration.pretty) rescue ''
    #     end
    #   else
    #     body = ''
    #   end

    #   Configuration.logger.log_response code || 'N/A', took || 'N/A', body || 'N/A'
    # end
  end

end
