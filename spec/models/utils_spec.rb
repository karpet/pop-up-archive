require 'spec_helper'

describe Utils do
  before { StripeMock.start }
  after { StripeMock.stop }
  good_test_url = ''
  bad_test_url=''
  not_audio_url=''

  it "has a logger" do
    Utils.logger.should_not be_nil
  end

  it "checks http resource exists" do
    Utils.http_resource_exists?(good_test_url).should be_truthy
  end

  it "checks http resource exists, follow redirect" do
    Utils.http_resource_exists?(good_test_url).should be_truthy
  end

  it "checks http resource and retries" do
    Utils.http_resource_exists?(bad_test_url, 2).should be_falsey
  end

  it "downloads a public file to tmp file" do
    pf = Utils.download_public_file(URI.parse(good_test_url))
    pf.size.should == 4128
  end

  it "croaks when unable to download a public file" do
    expect{ Utils.download_public_file(URI.parse(bad_test_url), 2) }.to raise_error(Exception)
  end

  it "checks for when a url is for an audio file" do
    base = 'http://prx.org/file.'
    Utils::AUDIO_EXTENSIONS.each do |ext|
      Utils.is_audio_file?(base+ext).should be_truthy
    end
  end

  it "checks for when a url is NOT for an audio file" do
    ['mov', 'doc', 'txt', 'html'].each do |ext|
      Utils.is_audio_file?(not_audio_url+ext).should_not be_truthy
    end
  end

  it "checks for when a url is for an image file" do
    Utils::IMAGE_EXTENSIONS.each do |ext|
      Utils.is_image_file?(not_audio_url+ext).should be_truthy
    end
  end

  it "checks for when a url is NOT for an image file" do
    ['mov', 'doc', 'txt', 'html'].each do |ext|
      Utils.is_image_file?(not_audio_url+ext).should_not be_truthy
    end
  end

  it "should generate random string" do
    Utils.generate_rand_str.length.should eq 10
  end

end
