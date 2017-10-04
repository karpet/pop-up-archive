require 'spec_helper'

describe ActiveAdminComment do

  it "should return all created in a particular month" do
    comments = ActiveAdminComment.created_in_month
    comments.size.should eq 0
  end

end
