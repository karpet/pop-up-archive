require 'subscription_plan'

class SubscriptionPlanCached

  # this class does *NOT* front a db table directly.
  # it is more of a write-through caching manager,
  # for keeping the Stripe subscription plans
  # in sync with the local db. The Stripe plan is authoritative.
  # We just sync it locally since (a) plans rarely change
  # and (b) we want to be able to save remote API calls
  # but still use/display user plan data.

  def self.all
    Rails.cache.fetch([:plans, :group, :all], expires_in: 30.minutes) do
      stripe_plans = Stripe::Plan.all(count: 100)
      stripe_plans.map {|p| new(p) }.tap do |plans|
        plans.each do |plan|
          Rails.cache.write([:plans, :individual, plan.id], plan, expires_in: 30.minutes)
        end
      end
    end
  end

  def self.ungrandfathered
    Rails.cache.fetch([:plans, :group, :ungrandfathered], expires_in: 30.minutes) do
      all.select { |p| (p.name ||'')[0] != '*' }
    end
  end

  def self.find(id)
    Rails.cache.fetch([:plans, :individual, id], expires_in: 30.minutes) do
      all.find { |p| p.id == id }
    end
  end

  # community() is essentially singletons
  # but for the purposes of testing we create-on-demand.
  def self.community
    if Rails.env.test?
      return create(plan_id: 'premium_community', name: 'Premium Community', amount: 0)
    end
    Rails.cache.fetch([:plans, :group, :premium_community], expires_in: 30.minutes) do
      spc = ungrandfathered.find { |p| p.id == 'premium_community' }
      if !spc
        raise "Cannot find 'premium_community' plan"
      end
      return spc
    end
  end

  def self.basic_community
    if Rails.env.test?
      return create(plan_id: 'community', name: 'Community', amount: 0)
    end 
    Rails.cache.fetch([:plans, :group, :community], expires_in: 30.minutes) do
      spc = ungrandfathered.find { |p| p.id == 'community' and p.name == 'Community'}
      if !spc
        raise "Cannot find 'community' plan"
      end 
      return spc 
    end 
  end

  # the create() method is really only for testing, since we manage Stripe
  # plans through the Stripe website.
  # We implement it here as a way of creating plans via stripe-mock gem
  # for the purposes of testing. Because we're testing, we avoid caching
  # because we want each rspec section to live indepedently.
  def self.create(options)
    if !Rails.env.test?
      raise "create() method only available for testing"
    end
    plan_id = options[:plan_id] || "#{options[:hours]||2}-#{SecureRandom.hex(8)}"
    interval = options[:interval] || 'month'

    # do not create it if already exists. instead return it.
    stripe_plans = Stripe::Plan.all(count: 100)
    stripe_plan = nil
    stripe_plans.each do|strplan|
      if strplan.id == plan_id
        stripe_plan = strplan
      end
    end
    if !stripe_plan
      init_opts = {
        id: plan_id,
        name: options[:name],
        amount: options[:amount],
        currency: 'USD',
        interval: interval,
      }
      # merge any other options not already present
      init_opts.merge!(options)
      begin
        stripe_plan = Stripe::Plan.create(init_opts)
      rescue Stripe::InvalidRequestError => err
        # re-throw with more detail
        raise "Could not create Stripe plan for '#{plan_id}': #{err}" + stripe_plans.inspect
      end
    end
    #puts "Stripe::Plan = " + stripe_plan.inspect
    spc = new(stripe_plan)

    # clear any caching. really.
    self.reset_cache

    #puts "SPC created: " + spc.inspect
    return spc
  end

  def self.reset_cache
    Rails.cache.delete([:plans, :group, :all])
    Rails.cache.delete([:plans, :group, :ungrandfathered])
    Rails.cache.delete([:plans, :group, :premium_community])
  end

  def initialize(plan)
    @id = plan.id
    @hours = calculate_plan_hours(plan.id)
    @name = plan.name
    @amount = plan.amount
    @interval = plan.interval
    SubscriptionPlan.sync_with_stripe(self)
  end

  def as_plan
    SubscriptionPlan.find_by_stripe_plan_id(self.id)
  end

  def is_community?
    self.id == 'premium_community' || self.name == "Premium Community"
  end

  def is_basic_community?
    self.id == 'community' || self.name == "Community"
  end

  # if the plan id has _business_ or _enterprise_ or _premium_ in it, we'll do premium transcripts
  def has_premium_transcripts?
    self.id.match(/_(business|enterprise|premium)_/) or self.id.match(/_(monthly|yearly)/) or self.is_community?
  end

  attr_reader :name, :amount, :hours, :id, :interval

  def eql?(plan)
    plan.id == id
  end

  alias_method :==, :eql?

  def monthly_amount
    if interval == 'month'
      amount
    else
      amount.fdiv(12)
    end
  end

  private

  def calculate_plan_hours(id)
    hours = id.split(/\-|_/)[0].to_i
    if hours == 0
      1
    else
      hours
    end
  end
end
