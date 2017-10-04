class Api::V1::UsersController < Api::V1::BaseController
  def me
  end

  def usage
    # optionally limit by month
    limit = nil
    if params[:limit]
      if params[:limit] == 'current'
        limit = DateTime.now.utc
      elsif params[:limit].match(/^\d\d\d\d\-?\d\d$/)
        ym    = params[:limit].match(/^(\d\d\d\d)\-?(\d\d)$/)
        limit = DateTime.parse(ym[1]+'-'+ym[2]+'-01')
      else
        limit = DateTime.parse(params[:limit])
      end
    end

    @usage = current_user.transcript_usage(limit)  # keyed by yyyymm in chron order
    if current_user.organization
      @usage[:organization] = current_user.organization.transcript_usage(limit)
    end
  end

end
