class Api::V1::SearchesController < Api::V1::BaseController
  
  def show
    prep_search
    # try try try to get some results. If none for AND search, expand to OR.
    if @es_resp.response.hits.total == 0
      Rails.logger.debug "zero hits for initial query. trying again with looser logical OR"
      params[:op] = 'OR'
      prep_search
    end 
    @search = ItemResultsPresenter.new(@es_resp.response)
    #Rails.logger.debug("pager_params=#{@searcher.pager_params.inspect}")
    respond_with @search 
  end

  def prep_search
    @searcher = ItemSearcher.new(params, current_user)
    @es_resp = @searcher.aggregation_search
    # @es_resp = @searcher.search
  end
 
end
