require 'spec_helper'

class TestApiController < ApplicationController
  include Api::BaseHelper
end

describe Api::BaseHelper do

  before { StripeMock.start }
  after { StripeMock.stop }

  it "should get total PUA hours" do
    Rails.cache.delete(:pua_total_time_in_hours)
    Rails.cache.delete(:pua_total_hours_on_pua)
    Rails.cache.delete(:pua_total_public_duration_sum)
    Rails.cache.delete(:pua_total_private_duration_sum)
    TestApiController.new.total_hours_on_pua.should match('\d+ hours \(\d+d: \d+h: \d+m: \d+s\)')
    TestApiController.new.total_time_in_hours.should match(/\d+hrs/)
    TestApiController.new.total_public_duration.should eq AudioFile.all_public_duration
    TestApiController.new.total_private_duration.should eq AudioFile.all_private_duration
    TestApiController.new.total_public_duration_dhms.should match('\d+ hours \(\d+d: \d+h: \d+m: \d+s\)')
    TestApiController.new.total_private_duration_dhms.should match('\d+ hours \(\d+d: \d+h: \d+m: \d+s\)')
  end

  it "should format time" do
    Api::BaseHelper::format_time(0).should eq '00:00:00'
  end

end
