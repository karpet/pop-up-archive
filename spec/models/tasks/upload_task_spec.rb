require 'spec_helper'

describe Tasks::UploadTask do
  before { StripeMock.start }
  after { StripeMock.stop }

  it "should set defaults" do
    task = Tasks::UploadTask.new(extras: {'user_id' => 1, 'filename' => 'test.wav', 'filesize' => 10000, 'last_modified' => '12345'})
    task.should be_valid
    task.identifier.should eq('eb3f9ccf1ddb6e442c71a614b3f8fe8af705f56a')
    task.extras.should have_key 'chunks_uploaded'
  end

  it "should get chunks_uploaded as array" do
    task = Tasks::UploadTask.new
    task.chunks_uploaded.should eq []
    task.extras['chunks_uploaded'] = "1,2,3"
    task.chunks_uploaded.should eq [1,2,3]
  end

  it "should set chunks_uploaded as array" do
    task = Tasks::UploadTask.new
    task.chunks_uploaded = [1,2,3]
    task.extras['chunks_uploaded'].should eq "1,2,3\n"
    task.chunks_uploaded.should eq [1,2,3]
  end

  it "should not mark completed on update of chunk" do
    audio_file = FactoryGirl.create :audio_file_private
    task = Tasks::UploadTask.new(extras: {'num_chunks' => 2, 'chunks_uploaded' => "1\n", 'key' => 'this/is/a/key.mp3'}, owner: audio_file)
    task.save!
    task.should be_created
    #task.run_callbacks(:commit)
    task.add_chunk!('2')
    #task.run_callbacks(:commit)
    task.should_not be_complete
  end

  it "should register failure correctly with parent audio_task" do
    audio_file = FactoryGirl.create :audio_file_private
    task = Tasks::UploadTask.new(extras: {'num_chunks' => 2, 'chunks_uploaded' => "1\n", 'key' => 'this/is/a/key.mp3'}, owner: audio_file)
    task.save!
    task.should be_created
    #STDERR.puts "is_uploaded? #{audio_file.is_uploaded?}"
    #STDERR.puts "is_copied? #{audio_file.is_copied?}"
    #STDERR.puts "incomplete_tasks== #{audio_file.tasks.unfinished.inspect}"
    audio_file.current_status.should eq AudioFile::UPLOADING_INPROCESS
    task.cancel!
    #STDERR.puts "is_uploaded? #{audio_file.is_uploaded?}"
    #STDERR.puts "has_failed_upload? #{audio_file.has_failed_upload?}"
    #STDERR.puts "all tasks== #{audio_file.tasks.inspect}"
    audio_file.current_status.should eq AudioFile::UPLOAD_FAILED
  end

end

