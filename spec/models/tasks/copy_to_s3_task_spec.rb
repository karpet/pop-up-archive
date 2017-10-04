require 'spec_helper'

describe Tasks::CopyToS3Task do
  before { StripeMock.start }
  after { StripeMock.stop }

  it "should set defaults" do

    task = Tasks::CopyToS3Task.new(
      identifier: 'copy_to_s3',
      storage_id: 2,
      extras: {
        'original'    => 'http://original.com/file.mp3',
        'destination' => 's3://file.mp3'
      })

    task.should be_valid
    task.identifier.should eq('copy_to_s3')
  end

  it "should update audio file on complete" do

    audio_file = FactoryGirl.create :audio_file
    storage = FactoryGirl.create :storage_configuration_archive
    storage_id = storage.id

    task = Tasks::CopyToS3Task.new(
      identifier: 'copy_to_s3',
      storage_id: storage_id,
      extras: {
        'original'    => 'http://original.com/file.mp3',
        'destination' => 's3://file.mp3'
      })

    task.owner = audio_file
    task.finish!

  end

end

