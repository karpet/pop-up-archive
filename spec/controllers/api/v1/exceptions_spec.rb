require 'spec_helper'

describe Api::V1::TestController do
  extend ControllerMacros

  before { StripeMock.start }
  after { StripeMock.stop }

  before :each do
    request.accept = "application/json"
  end

  it 'should return 404' do
    get "show", :id => "no-such-record", format: :json
    expect(response.status).to eq(404)
    resp = JSON.parse(response.body)
    #puts resp.inspect
    expect(resp["error"]).to eq('not found')
    expect(resp["status"]).to eq(404)
  end

  it 'should return 500' do
    get "croak", format: :json
    expect(response.status).to eq(500)
    resp = JSON.parse(response.body)
    #puts resp.inspect
    expect(resp["error"]).to eq('Internal server error')
    expect(resp["status"]).to eq(500)
  end

end
