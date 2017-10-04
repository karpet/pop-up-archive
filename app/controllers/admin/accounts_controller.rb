class Admin::AccountsController < Admin::BaseController
  load_and_authorize_resource :class => "User"
  def index
    @accounts = @accounts.over_limits
  end

  def total_usage
    @accounts = @accounts.paginate(:page => params[:page] || 1,
                                   :per_page => 20,
                                   :order => ('used_metered_storage_cache DESC,
                                                               created_at DESC'))
  end  

end
