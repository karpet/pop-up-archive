require 'stopwords/snowball/filter'
require 'lucene_query_parser'
require 'erb'

class ItemSearcher
  include ERB::Util

  attr_accessor :params, :query_str, :sort_by, :filters, :page, :def_op, :results, :similar_results, :stopped_words, :alt_query

  MIN_FIELDS = ['id', 'title', 'collection_title', 'tags', 'image_url', 'audio_files']

  def pager_params
    { size: @size, from: @from, page: @page }
  end

  def initialize(params, current_user=nil)
    @params    = params
    @query_str = params[:q] || params[:query]
    @sort_by   = params[:sort_by] || params[:sortBy]
    @sort_order = params[:sort_order] || params[:sortOrder]
    if params[:s]
      sstr = params[:s].split(/\ +/)
      @sort_by = sstr[0]
      @sort_order = sstr[1]
    end
    @filters   = params[:f] || params[:filters]
    @page      = params[:page] || 1
    @size      = params[:size] || 20
    @from      = params[:from]
    @def_op    = params[:op] || 'AND'
    @current_user = current_user || params[:current_user] || nil
    @debug     = params[:debug]
    @include_related = params[:related]
    @aggregations = params[:aggs] || params[:aggregations]
    @agg_count = params[:ac] || 10
    @prefix_agg = params[:preq]
    # operator may only be AND or OR
    if @def_op != 'AND' && @def_op != 'OR'
      @def_op = 'AND'
    end
    # this calculation is different than in Audiosearch, where RESULTS_PER_PAGE
    # is ignored.
    @page = @page.to_i
    if !@page || @page <= 1
      @from = 0
    else
      @from = (((@page - 1) * 20) + 1)
    end
    if !@size && !@from && @page > 0
      @from = (@page - 1) * Item::SEARCH_RESULTS_PER_PAGE
      @size = Item::SEARCH_RESULTS_PER_PAGE
    end
    filter_query_string  # prefilter
  end

  def has_stopped_words?
    @stopped_words && @stopped_words.size > 0
  end

  def has_filters?
    @filters && @filters.size > 0
  end

  def alt_query_encoded
    url_encode(alt_query)
  end

  # basic search
  # returns ES Response object.
  # def search
  #   query_dsl = prep_search_query
  #   if @size && @from
  #     @results = Item.search(query_dsl.to_json, { :size => @size.to_i, :from => @from.to_i })
  #   else
  #     @results = Item.search(query_dsl.to_json).page(@page)
  #   end
  #   prep_search_results
  #   @results
  # end

  def aggregation_search
    query_dsl = prep_search_query
    @results = Item.search(query_dsl.to_json)
    prep_search_results
    @results
  end

  def prep_search_query
    query_builder = QueryBuilder.new({
      :op      => @def_op,
      :query   => @query_str,
      :sort_by => @sort_by,
      :sort_order => @sort_order,
      :filters => @filters,
      :page    => @page.to_s,
      :agg_count => @agg_count,
      :prefix_agg => @prefix_agg,
      :aggregations => @aggregations
    }, @current_user)
    has_sort = @sort_by && @sort_order
    has_query = @query_str.present?
    search_query = Search.new(Item.index_name) do
      query_builder.query do |q|
        query(&q)
      end

      query_builder.filters.each do |my_filter|
        filter(my_filter.type, my_filter.value)
      end

      if query_builder.aggregations.is_a? String
        facet_agg(query_builder.aggregations)
      else query_builder.aggregations do |my_agg|
          facet_agg(my_agg.name, &my_agg)
        end
      end

      agg_count(query_builder.agg_count) if query_builder.agg_count

      from_for_aggs(query_builder.page) if query_builder.page

      filter_with_prefix(query_builder.prefix_agg) if query_builder.prefix_agg
      # determine sort order
      if has_sort
        #Rails.logger.warn("has_sort==true. column==#{query_builder.sort_column} dir=#{query_builder.sort_order}")
        sort do
          by query_builder.sort_column, query_builder.sort_order
        end
      elsif !has_query
        sort do
          by 'created_at', 'desc'
        end
      else
        sort do
          by '_score', 'desc'
        end
      end
      highlight Hash[ ['transcript', 'title', 'description'].map {|f| [f, { number_of_fragments: 0 }] } ]
    end

    # TODO would be nice if query_builder could do this for us.
    sq_hash = search_query.to_agg_hash
    query={}
    query[:bool]={}
    if @query_str && @query_str != '*'
      query_parts = @query_str.split(',');
      fields = ['title^2', 'description', 'tag', 'entity', 'transcript', 'collection_title']
      query[:bool][:must] = []
      query_parts.each  do |part|
        breaks=part.split(':')
        if breaks.length > 1
          field=[breaks[0]]
          content= { multi_match: { query: breaks[1], operator: @def_op, fields: field, tie_breaker: 20.0 } }
        else
          content= { multi_match: { query: breaks[0], operator: @def_op, fields: fields, tie_breaker: 20.0 } }
        end
        query[:bool][:must].push(content)
      end
    else
      query[:bool][:must] = { match_all: {}}
    end
    sq_hash[:query] = query
    sq_hash[:query][:bool][:filter] = { bool: search_query.filters}
    # Rails.logger.debug JSON.pretty_generate(sq_hash)
    sq_hash
  end

  # like search() only pared-down response with no transcripts.
  def simple_search
    query_dsl = prep_search_query
    query_dsl[:_source] = { include: MIN_FIELDS }
    if @size && @from
      @results = Item.search(query_dsl.to_json, { :size => @size.to_i, :from => @from.to_i })
    else
      @results = Item.search(query_dsl.to_json).page(@page)
    end
  end

  # apply some simple filtering to query string
  # for characters we do not support from users.
  # this is a subset of
  # http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-query-string-query.html#_reserved_characters
  def filter_query_string
    return unless @query_str.present?
    # try parsing. if we can't, then strip characters.
    # this allows for savvy users to actually exercise features, w/o penalizing inadvertent strings.
    parser = self.class.get_query_parser
    errloc = parser.error_location(@query_str)
    if errloc
      @query_str.gsub!(/[\&\|\>\<\!\(\)\{\}\[\]\^\~\\\/]+/, '')
      @query_str.gsub!(/\ +/, ' ')  # reduce multiple spaces to singles
      # if we have just a single double quote mark, strip it too
      if @query_str.match(/"/) and !@query_str.match(/".+?"/)
        @query_str.gsub!(/"/, '')
      end
    end
  end

  def self.get_query_parser
    LuceneQueryParser::Parser.new :term_re => "\\p\{Word\}\\.\\*\\-\\'"
  end

  def urlify(str)
    str.downcase.gsub(/\W/, '-').gsub(/--/, '-').gsub(/^\-|\-$/, '')
  end

  def prep_search_results

    # flag the highlighted transcript lines
    # NOTE we must use the raw internal methods so that we alter the internal structure.
    @results.response.hits.hits.each do |r|
      r._source.collection_title_url = urlify(r._source.collection_title)
      hl_lookup = {}
      excerpts  = []
      if r.try(:highlight).try(:transcript)
        r.highlight.transcript.each do |snip|
          bare_snip = snip.gsub(/<\/?em>/, '')
          hl_lookup[bare_snip] = snip
        end
      end
      # flag each transcript item that matches
      r._source.transcripts.each_with_index do |t, idx|
        if hl_lookup.has_key? t.transcript
          t.is_match = true
          t.highlight = hl_lookup[t.transcript]
          # create excerpt group
          excerpt = []
          if idx > 0 && r._source.transcripts[idx-1]["start_time"] < r._source.transcripts[idx]["start_time"]
            if r._source.transcripts[idx-1]["is_match"] == true && r._source.transcripts[idx+1]
              excerpts[excerpts.length-1].push r._source.transcripts[idx+1]
              next
            else
              excerpt.push r._source.transcripts[idx-1]
            end
          end
          excerpt.push t
          if r._source.transcripts[idx+1]
            excerpt.push r._source.transcripts[idx+1]
          end
          excerpts.push excerpt
        end
      end
      # tack on excerpts
      r._source.excerpts = excerpts
    end
  end

  # currently a no-op placeholder
  def prep_similar_item_results
  end

  # currently a no-op placeholder
  def prep_similar_query_results
  end

  # we return one of these:
  # * autocomplete are terms strings for when there are zero hits.
  # * result suggestions are actual hits, categorized by where they matched.
  def prep_suggest_results(results)
    resp = {
      autocomplete: build_autocomplete_suggestions( results.suggest ),
    }
    if results.hits.total != 0
      resp[:hits] = build_hit_suggestions( results.hits )
    end
    resp
  end

  # returns array of strings
  def build_autocomplete_suggestions(sugg)
    acs = []
    sugg.keys.each do |ft|
      sugg[ft].each do |v|
        v.options.each do |o|
          acs.push o.text
        end
      end
    end
    acs.uniq
  end

  def build_hit_suggestions(hits)
    # determine which field matched based on 'highlight' keys,
    # and construct each rec based on that.
    recs = { tags: [], collections: [], items: [], }
    hits.hits.each do |hit|
      if hit.highlight
        hit.highlight.keys.each do |fn|
          if fn == 'title' || fn == 'description'
            item = hit._source
            item.idHex = item.id.to_s(16)
            recs[:items].push item
          elsif fn == 'collection_title'
            recs[:collections].push( { :title => hit.highlight[fn].first, :id => hit._source.collection_id } )
          elsif fn == 'tag'
            recs[:tags].push hit.highlight[fn]
          end
        end
      else
      # assume it is an Item
        item = hit._source
        item.idHex = item.id.to_s(16)
        recs[:items].push item
      end
    end

    # de-dupe items
    recs[:items].uniq! { |i| i.id }

    # de-dupe and de-highlight non-items
    [:categories, :networks, :tags].each do |t|
      recs[t] = recs[t].map {|v| v.first.gsub(/<\/?em>/, '')}.select {|v| v.first.length > 0 && v.first.match(/\S/) }.uniq { |v| v.downcase }
    end
    recs[:collections] = recs[:collections].uniq { |s| s[:id] }
    recs[:collections].each do |s|
      s[:title].gsub!(/<\/?em>/, '')
    end

    recs
  end
end
