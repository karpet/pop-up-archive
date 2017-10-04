class Api::V1::SubscriptionsController < Api::V1::BaseController

  def update
    plan = SubscriptionPlanCached.find(params[:subscription][:plan_id])
    begin
      current_user.subscribe!(plan, params[:subscription][:offer])
      render status: 200, json: plan
    rescue Stripe::CardError => err
      Rails.logger.error(err)
      render status: 431, json: { error: 'Stripe subscription change failed' }
    rescue => err
      Rails.logger.error(err)
      render status: 431, json: { error: 'Stripe subscription change failed' }
    end
  end

end
