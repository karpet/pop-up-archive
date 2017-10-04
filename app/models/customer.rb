class Customer
  attr_reader :id, :card, :trial, :interval, :subscr_meta

  def initialize(stripe_customer=nil, *attrs)
    if !stripe_customer.nil?
      @id = stripe_customer.id
      subscr = stripe_subscription(stripe_customer)
      if subscr
        @plan_id = subscr.plan.id
        if subscr.trial_end.present?
          @trial = (Time.at(subscr.trial_end).to_date - Date.today).to_i
        else
          @trial = 0
        end
        @subscr_meta = subscr.metadata
      end
      @card = stripe_customer.respond_to?(:cards) ? stripe_customer.cards.data[0].as_json.try(:slice, *%w(last4 type exp_month exp_year)) : {}
    else
      hashref = attrs.is_a?(Array) ? attrs.first : attrs
      @id = hashref[:id]
      @card = hashref[:card] || {}
      @plan_id = hashref[:plan_id]
      @trial = hashref[:trial] || 0
      @interval = hashref[:interval]
      @subscr_meta = hashref[:meta]
    end
  end

  def in_first_month?
  # another way of saying, was subscription initiated last month?
  # since the first interval is a 'trial' status.
  # Assumption: customer creation date always coincides with a subscription.
    cust = stripe_customer
    if cust.nil?
      return nil
    end
    start = cust.created
    # test env uses hardcoded customer.created date that ruins our logic.
    if Rails.env.test?
      subscr = stripe_subscription(cust)
      start = subscr.metadata[:start] || subscr.start
    end
    #STDERR.puts "start==#{start}  start_of_this_month==#{self.class.start_of_this_month}"
    start.to_i >= self.class.start_of_this_month
  end

  def is_interim_trial?
    cust = stripe_customer
    return nil unless cust
    subscr = stripe_subscription(cust)
    return nil unless subscr
    if subscr.status == "trialing" && subscr.trial_end && subscr.trial_end >= self.class.end_of_this_month
      return true
    else
      return false
    end
  end

  def self.start_of_this_month
    Time.now.utc.beginning_of_month.to_i
  end

  def self.end_of_this_month
    Time.now.utc.end_of_month.to_i
  end

  def plan_id
    @plan_id || SubscriptionPlanCached.community.id
  end

  def plan
    SubscriptionPlanCached.find(plan_id) or raise "No plan defined for plan_id #{plan_id}"
  end

  def eql?(customer)
    customer.id == id
  end

  def self.get_stripe_customer(cust_id)
    cust = nil
    begin
      cust = Stripe::Customer.retrieve(cust_id)
    rescue Stripe::InvalidRequestError => err
      Rails.logger.warn "Stripe Error: #{err.message} #{err.http_status}"
      if err.http_status == 404
        if err.message.match(/object exists in live mode, but a test mode key/)
          return nil
        elsif err.message.match(/No such customer/)
          return nil
        else
          raise "Cannot match 404 error: '#{err.message}'"
        end
      else
        raise "Caught Stripe InvalidRequestError #{err}"
      end
    rescue => err
      raise "Caught Stripe error #{err}"
    end
    cust
  end

  def stripe_customer
    self.class.get_stripe_customer(id)
  end

  def stripe_subscription(stripe_cus=stripe_customer)
    return nil unless stripe_cus && stripe_cus.try(:subscriptions)
    stripe_cus.subscriptions.first
  end

  alias :eql? :==

  def subscribe_to_community
    cust = stripe_customer
    if cust.respond_to? :deleted and cust.deleted == true
      Rails.logger.warn "**TODO** customer #{cust.id} exists but has been deleted -- cannot subscribe to community but treating as if we can"
      STDERR.puts "**TODO** customer #{cust.id} exists but has been deleted -- cannot subscribe to community but treating as if we can"
      Rails.cache.delete([:customer, :individual, cust.id])
      return SubscriptionPlanCached.community
    end
    community_plan = SubscriptionPlanCached.community
    subscr = stripe_subscription(cust)
    if subscr
      # has existing. update it.
      subscr.plan = community_plan.id
      subscr.save
    else
      # no subscription yet. create it.
      cust.subscriptions.create(:plan => community_plan.id)
    end
    Rails.cache.delete([:customer, :individual, cust.id])
    return community_plan
  end

  def self.generic_community
    return new(nil, :id => 'generic-community-customer', :plan_id => SubscriptionPlanCached.community.id)
  end
end
