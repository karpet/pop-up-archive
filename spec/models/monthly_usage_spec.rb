require 'spec_helper'

describe MonthlyUsage do

  before { StripeMock.start }
  after { StripeMock.stop }

  let(:user) { FactoryGirl.create(:user) }

  it "should create a valid entry" do
    usage = MonthlyUsage.create!(use: 'test', entity: user, month: 1, year: 2014, value: 100)
    usage.entity_id.should == user.id
  end

end
