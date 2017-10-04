class SubscriptionPlan < ActiveRecord::Base
  attr_accessible :name, :hours, :amount, :interval, :stripe_plan_id, :pop_up_hours

  def self.sync_with_stripe(spc)
    # spc is SubscriptionPlanCached (simple object)
    # we verify our local copy, if it exists, is identical to Stripe's.
    sp = find_by_stripe_plan_id(spc.id)
    if sp.nil?
      # we don't yet have a local copy. create one.
      sp = self.create(
      :stripe_plan_id => spc.id,
      :name => spc.name,
      :interval => spc.interval,
      :hours => spc.hours,
      :pop_up_hours => spc.hours.to_i,
      :amount => spc.amount
      )
    else

  # :nocov:

      # compare and update if necessary
      needs_update = false
      if spc.name != sp.name
        Rails.logger.warn("sp id '#{sp.id} name has changed from '#{sp.name}' to '#{spc.name}'")
        sp.name = spc.name
        needs_update = true
      end
      if spc.interval != sp.interval
        Rails.logger.warn("sp id '#{sp.id}' interval has changed from '#{sp.interval}' to '#{spc.interval}'")
        sp.interval = spc.interval
        needs_update = true
      end
      if spc.hours.to_i != sp.hours.to_i
        Rails.logger.warn("sp id '#{sp.id}' hours has changed from '#{sp.hours}' to '#{spc.hours}'")
        sp.hours = spc.hours
        needs_update = true
      end
      if spc.hours.to_i != sp.pop_up_hours
        Rails.logger.warn("sp id '#{sp.id}' pop_up_hours has changed from '#{sp.pop_up_hours}' to '#{spc.hours.to_i}'")
        sp.pop_up_hours = spc.hours.to_i
        needs_update = true
      end
      if spc.amount.to_i != sp.amount.to_i
        Rails.logger.warn("sp id '#{sp.id}' amount has changed from '#{sp.amount}' to '#{spc.amount}'")
        sp.amount = spc.amount
        needs_update = true
      end
      sp.save if needs_update

  # :nocov:

    end
    return sp
  end

  # return a SubscriptionPlanCached object
  def as_cached
    return SubscriptionPlanCached.find(self.stripe_plan_id)
  end

  # if the plan id has _business_ or _enterprise_ or _premium_ in it, we'll do premium transcripts  #or for new plans 'monthly' or 'yearly'
  def has_premium_transcripts?
    self.stripe_plan_id.match(/_(business|enterprise|premium)_/) or self.stripe_plan_id.match(/_(monthly|yearly)/)
  end

end
