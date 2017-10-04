require 'spec_helper'

describe Organization do
  before { StripeMock.start }
  after { StripeMock.stop }
  
  it "can have collections" do
    @organization = FactoryGirl.create :organization
    @organization.collections << FactoryGirl.create(:collection)
    @organization.collections.count.should eq 1
  end

  it "can chew on raw sql for transcripts since" do
    Organization.get_org_ids_for_transcripts_since.should eq [] # no transcripts
  end

  it "should add User to team" do
    @org = FactoryGirl.create :organization
    @user = FactoryGirl.create :user
    @org.billable_collections.size.should eq 0
    @user.billable_collections.size.should eq 1
    @org.add_to_team(@user)
    @org.save!
    @user.organization.should eq @org
    # since the user's only collection was empty, it is soft-deleted
    @org.billable_collections.size.should eq 0
    @user.reload
    @user.billable_collections.size.should eq 1 # soft-deleted and still assigned.

    # second user with a non-empty collection
    @user2 = FactoryGirl.create :user
    @item = FactoryGirl.create :item
    @user2.collections.first.items << @item
    @user2.save!
    @user2.billable_collections.size.should eq 1
    @org.add_to_team(@user2)
    @org.save!
    @org.billable_collections.size.should eq 1
    @user2.reload
    @user2.billable_collections.size.should eq 0
    @org.owns_collection?( @org.billable_collections.first ).should be_truthy
    @org.has_grant_for?( @org.billable_collections.first ).should be_truthy

  end

  it "should invite user to become an org member" do
    @org = FactoryGirl.create :organization
    @user = FactoryGirl.create :user
    @org.invited_users.size.should eq 0
    expect { @org.invite_user(@user) }.to change { ActionMailer::Base.deliveries.count }.by(1)
    @org.invited_users.size.should eq 1
    @user.org_invite_url(@org).should match('/'+@org.id.to_s+'/')
    @user.confirm_org_member_invite(@org)
    @user.invitation_accepted_at.should be_truthy
  end

  it "basic methods" do
    @org = FactoryGirl.create :organization
    @org.plan.should eq SubscriptionPlanCached.community
    @org.update_usage_report!
    @org.used_metered_storage.should eq 0
    @org.used_unmetered_storage.should eq 0
    @org.owner_contact.should eq '(nil)'
    @org.pop_up_hours.should eq 1
    @org.entity.should eq @org
  end

end
