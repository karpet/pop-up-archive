class Api::V1::TestController < Api::V1::BaseController
  def croak 
    raise "This is a fatal error"
  end

  def show
    if params[:id] == 'no-such-record'
      raise ActiveRecord::RecordNotFound, "no such record"
    else
      {}
    end
  end

end
