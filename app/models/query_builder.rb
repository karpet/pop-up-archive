class QueryBuilder
  attr_accessor :params, :current_user

  def initialize(params, current_user)
    @params = params
    @current_user = current_user
  end

  def query
    if query_string
      yield QueryString.new(query_string)
    end
  end

  def agg_count
    @params[:agg_count] if @params[:agg_count]
  end

  def prefix_agg
    @params[:prefix_agg]if @params[:prefix_agg]
  end

  def aggregations
    if agg_params.is_a? String
       agg_params
    else agg_params.map do |name, details|
      Facet.new(name, details).tap do |agg|
        yield agg if block_given?
      end
      end
    end
  end

  def page
    (params[:page]).to_i || 1
  end

  def filters
    filters=[]
    if params[:filters]
      sub_filters=[]
      params[:filters].each do |name, details|
        details.parse_csv.each do |val|
          sub_filters << Filter.new(name, val)
        end
      end
      filters << AndFilter.new(sub_filters)
    end
    filters << current_user_filter
    filters
  end

  def current_user_filter
    if current_user.present?
      OrFilter.new([Filter.new(:collection_id, type: 'terms', value: current_user.searchable_collection_ids), public_filter])
    else
      OrFilter.new([public_filter,nil])
    end
  end

  def public_filter
    Filter.new(:is_public, type:'term', value: 'true')
  end

  def sort_column
    params[:sort_by] || '_score'
  end

  def sort_order
    params[:sort_order] || 'desc'
  end

  private

  def query_string
    params[:query]
  end

  def agg_params
    if params[:aggs].present?
      params[:aggs]
    elsif params[:agg].present?
      if params[:agg].kind_of? String
        {params[:agg] => {}}
      else
        {params[:agg].delete(:name) => params[:facet]}
      end
    elsif params[:aggregations].present?
      params[:aggregations]
    else
      default_aggs
    end
  end

  def default_aggs
    #might need to add default hash values in here if ES doesn't autopopulate
    {interviewers:{}, interviewees:{}, tags:{}, collection_id:{}, creators:{}, hosts:{}, producers:{}, guests:{}, entities:{}}
  end

end
