require 'spec_helper'

describe SubscriptionPlanCached do

  before { StripeMock.start }
  after { StripeMock.stop }

  before do
    @stripe_plan = SubscriptionPlanCached.create name: 'Test Plan', amount: 10000, hours: 200
    SubscriptionPlanCached.create name: "*test grandfathered", amount: 100, hours: 1
  end

  let (:plan) { SubscriptionPlanCached.all.first }

  let (:stripe_plan) { @stripe_plan }

  it 'can fetch all plans from the server' do
    SubscriptionPlanCached.all.size.should eq 2
  end

  it 'wraps all query results in a local object' do
    plan.should be_a SubscriptionPlanCached
  end

  it 'gets the name from the stripe object' do
    plan.name.should eq stripe_plan.name
  end

  it 'gets the hours from the stripe ID (first number, separated by _ or -)' do
    plan.hours.should eq 200
  end

  it 'defaults to 2 hours as a minimum' do
    stripe_plan = Stripe::Plan.create(name: 'Test Again Plan', amount: 0, id: 'malformed', currency: 'usd', interval: 'month')
    plan = SubscriptionPlanCached.new(stripe_plan)
    plan.hours.should eq 1
  end

  it 'gets the dollar amount from the stripe object' do
    plan.amount.should eq 10000
  end

  it 'is marshallable' do
    Marshal.dump(plan)
  end

  it 'can query for ungrandfathered plans without a * at the start of the name' do
    SubscriptionPlanCached.ungrandfathered.size.should eq 1
  end

  it "can return basic_community" do
    SubscriptionPlanCached.basic_community.name.should eq 'Community'
  end

  it "can create trial plan for tests" do
    trial_plan    = SubscriptionPlanCached.create trial_period_days: 30, hours: 1, amount: 2000, name: 'Free Trial'
    stripe_helper = StripeMock.create_test_helper
    card_token    = stripe_helper.generate_card_token
    user          = FactoryGirl.create :user
    user.subscribe!(trial_plan, 'radiorace')
  end

  it "can discern premium plans" do
    plan = stripe_plan.as_plan
    plan.has_premium_transcripts?().should be_falsey
    stripe_plan.has_premium_transcripts?().should be_falsey
  end

end
