object nil

node(:DEBUG) { true } if @debug
node(:facets) { @search.facets }
node(:total_hits) { @search.total }
node(:max_score) { @search.max_score }
node(:page) { params[:page] || 1 }
node(:query) { params[:query] }
node(:results) { @search.format_results }

