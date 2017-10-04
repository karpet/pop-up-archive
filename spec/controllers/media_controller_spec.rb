require 'spec_helper'
require 'uri'
describe MediaController do
  extend ControllerMacros

  before { StripeMock.start }
  after { StripeMock.stop }

  describe "GET /media" do

    it "/media route should match" do
      af = FactoryGirl.create :audio_file
      url = af.public_url()
      path = URI(url).path
      #STDERR.puts "audio_file #{af.id} => #{path}"
      expect(:get => path).to route_to(
        :controller => 'media',
        :action    => 'show',
        :token     => af.public_url_token,
        :expires   => "0",
        :use       => "public",
        :class     => "audio_file",
        :id        => af.id.to_s,
        :name      => "test",
        :extension => "mp3"
      ) 
    end

    it "/media route should match with filename with dots in it" do
      af = FactoryGirl.create :audio_file
      af.update_file!('foo.bar.dots.mp3', 0)
      url = af.public_url()
      path = URI(url).path
      #STDERR.puts "audio_file #{af.id} => #{path}"
      expect(:get => path).to route_to(
        :controller => 'media',
        :action    => 'show',
        :token     => af.public_url_token,
        :expires   => "0",
        :use       => "public",
        :class     => "audio_file",
        :id        => af.id.to_s,
        :name      => "foo-bar-dots",
        :extension => "mp3"
      )
    end

    it "should redirect '/media/:class/:idhex/:name.:extension' (permanent)" do
      af = FactoryGirl.create :audio_file
      af.update_file!('foo.bar.dots.mp3', 0)
      get 'permanent', idhex: af.id.to_s(16), class: 'audio_file', extension: 'mp3', name: 'foo.bar.dots'
      response.should be_redirect
    end

    it "should redirect '/media/:token/:expires/:use/:class/:id/:name.:extension' (show)" do
      af = FactoryGirl.create :audio_file
      get 'show', token: af.public_url_token, expires: 0, use: 'public', class: 'audio_file', id: af.id, name: 'test', extension: 'mp3'
      response.should be_redirect
    end

    it "should 401 a bad media URL" do
      af = FactoryGirl.create :audio_file
      get 'show', token: af.public_url_token, expires: 0, use: 'badusestring', class: 'audio_file', id: af.id, name: 'test', extension: 'mp3'
      response.status.should eq 401
    end

  end

end

