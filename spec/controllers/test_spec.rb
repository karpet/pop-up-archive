require 'spec_helper'

describe TestController do
  extend ControllerMacros

  before { StripeMock.start }
  after { StripeMock.stop }

  it 'should return 404' do
    get "show", format: 'json'
    expect(response.status).to eq(404)
    resp = JSON.parse(response.body)
    expect(resp["error"]).to eq('not found')
    expect(resp["status"]).to eq(404)

    get 'show', format: :html
    expect(response.status).to eq(404)
  
    get 'show', format: :srt
    expect(response.status).to eq(404)
    expect(response.body).to match('not found')

    get 'show', format: :txt
    expect(response.status).to eq(404)
    expect(response.body).to match('not found')

    get 'show', format: :xml
    expect(response.status).to eq(404)
    expect(response.body).to match('not found')

  end

end
