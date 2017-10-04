require 'spec_helper'

describe Charge do

  let(:user) { FactoryGirl.create :user }
  before { StripeMock.start }
  after { StripeMock.stop }

  it "should associate with User" do
    charge = Charge.create( :ref_id => 'abc123', :amount => 123.45, :ref_type => 'charge', :transaction_at => DateTime.now.utc)
    user.charges << charge
    user.save!
    user.charges.first.ref_id.should eq 'abc123'
  end

end

