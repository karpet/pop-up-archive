require 'spec_helper'

describe Tasks::SpeechmaticsTranscribeTask do

  before { StripeMock.start }
  after { StripeMock.stop }

  let(:user) { FactoryGirl.create :user }
  let(:audio_file) { FactoryGirl.create :audio_file_private, user_id: user.id }
  let(:task) { Tasks::SpeechmaticsTranscribeTask.new(owner: audio_file, extras: {'user_id' => user.id}) }

  let(:response) {
    m = Hashie::Mash.new
    m.body = {
      "format" => "1.0",
      "job" => {
        "lang"=>"en-US",
        "user_id"=>843,
        "name"=>"fake.mp3",
        "duration"=>47,
        "created_at"=>"Fri May 13 20:13:44 2016",
        "id"=>458359
      },
      "speakers" => [
        {"duration"=>"5.480","confidence"=>nil,"name"=>"M2","time"=>"11.470"},
  		  {"duration"=>"8.430","confidence"=>nil,"name"=>"M1","time"=>"16.950"},
  		  {"duration"=>"9.710","confidence"=>nil,"name"=>"M7","time"=>"25.380"},
  		  {"duration"=>"10.500","confidence"=>nil,"name"=>"M3","time"=>"35.090"},
  		  {"duration"=>"1.550","confidence"=>nil,"name"=>"M6","time"=>"45.590"},
      ],
      "words" => [
        {"duration"=>"0.270","confidence"=>"0.995","name"=>"That","time"=>"11.470"},
    		{"duration"=>"0.170","confidence"=>"0.977","name"=>"it","time"=>"11.740"},
    		{"duration"=>"0.150","confidence"=>"0.346","name"=>"was","time"=>"12.140"},
    		{"duration"=>"0.180","confidence"=>"0.554","name"=>"in","time"=>"12.690"},
    		{"duration"=>"0.160","confidence"=>"0.472","name"=>"it","time"=>"12.870"},
    		{"duration"=>"3.920","confidence"=>nil,"name"=>".","time"=>"13.030"},
    		{"duration"=>"0.170","confidence"=>"0.989","name"=>"She","time"=>"16.950"},
    		{"duration"=>"0.250","confidence"=>"0.959","name"=>"was","time"=>"17.120"},
    		{"duration"=>"0.150","confidence"=>"0.360","name"=>"right","time"=>"18.600"},
    		{"duration"=>"4.260","confidence"=>nil,"name"=>".","time"=>"18.750"},
    		{"duration"=>"0.160","confidence"=>"0.790","name"=>"Our","time"=>"25.380"},
    		{"duration"=>"0.320","confidence"=>"0.995","name"=>"picture","time"=>"25.540"},
    		{"duration"=>"0.080","confidence"=>"0.995","name"=>"of","time"=>"25.860"},
    		{"duration"=>"0.060","confidence"=>"0.995","name"=>"the","time"=>"25.940"},
    		{"duration"=>"0.500","confidence"=>"0.995","name"=>"computer","time"=>"26.000"},
    		{"duration"=>"1.200","confidence"=>nil,"name"=>".","time"=>"26.500"},
    		{"duration"=>"0.110","confidence"=>"0.995","name"=>"The","time"=>"28.720"},
    		{"duration"=>"0.370","confidence"=>"0.944","name"=>"public","time"=>"28.830"},
    		{"duration"=>"0.300","confidence"=>"0.995","name"=>"picture","time"=>"29.200"},
    		{"duration"=>"0.070","confidence"=>"0.995","name"=>"of","time"=>"29.500"},
    		{"duration"=>"0.070","confidence"=>"0.995","name"=>"the","time"=>"29.570"},
    		{"duration"=>"0.400","confidence"=>"0.995","name"=>"computer","time"=>"29.640"},
    		{"duration"=>"0.240","confidence"=>"0.905","name"=>"keeps","time"=>"30.040"},
    		{"duration"=>"0.450","confidence"=>"0.995","name"=>"changing","time"=>"30.280"},
    		{"duration"=>"0.260","confidence"=>"0.995","name"=>"and","time"=>"32.160"},
    		{"duration"=>"0.420","confidence"=>"0.995","name"=>"almost","time"=>"32.420"},
    		{"duration"=>"0.190","confidence"=>"0.881","name"=>"right","time"=>"33.930"},
    		{"duration"=>"0.970","confidence"=>nil,"name"=>".","time"=>"34.120"},
    		{"duration"=>"0.220","confidence"=>"0.532","name"=>"OK","time"=>"35.090"},
    		{"duration"=>"0.210","confidence"=>"0.968","name"=>"sure","time"=>"35.310"},
    		{"duration"=>"0.130","confidence"=>"0.380","name"=>"you","time"=>"41.420"},
    		{"duration"=>"0.280","confidence"=>"0.933","name"=>"can't","time"=>"41.740"},
    		{"duration"=>"0.090","confidence"=>"0.995","name"=>"do","time"=>"42.020"},
    		{"duration"=>"0.220","confidence"=>"0.975","name"=>"anything","time"=>"42.110"},
    		{"duration"=>"0.220","confidence"=>"0.970","name"=>"about","time"=>"42.330"},
    		{"duration"=>"0.100","confidence"=>"0.565","name"=>"it","time"=>"42.550"},
    		{"duration"=>"0.310","confidence"=>"0.529","name"=>"right","time"=>"45.170"},
    		{"duration"=>"0.110","confidence"=>nil,"name"=>".","time"=>"45.480"},
    		{"duration"=>"0.230","confidence"=>"0.870","name"=>"Yeah","time"=>"45.590"},
    		{"duration"=>"0.160","confidence"=>"0.296","name"=>"yeah","time"=>"46.140"},
    		{"duration"=>"0.840","confidence"=>nil,"name"=>".","time"=>"46.300"}
      ]
    }
    m.speakers = m.body.speakers
    m.words = m.body.words
    m
  }

  context "create job" do


    it "has audio_file url" do
      url = task.audio_file_url
    end

    it "downloads audio_file" do
      task.set_task_defaults
      audio_file.item.token = "untitled.NqMBNV.popuparchive.org"
      Utils.should_receive(:download_file).and_return(File.open(test_file('test.mp3')))

      data_file = task.download_audio_file
      data_file.should_not be_nil
      data_file.is_a?(File).should be_truthy
    end

    it "makes callback url" do
      task.set_speechmatics_defaults
      task.call_back_url.should eq "http://test.popuparchive.com/speechmatics_callback/files/task/#{task.extras['public_id']}"
    end

    it "processes transcript result" do
      trans = task.process_transcript(response)
      trans.timed_texts.count.should eq 7
      trans.timed_texts.first.text.should eq "That it was in it."
      trans.speakers.count.should eq 5
      trans.speakers.first.name.should eq "M2"
      trans.timed_texts.first.speaker_id.should eq trans.speakers.first.id
      trans.timed_texts.last.speaker_id.should eq trans.speakers.last.id

      #STDERR.puts trans.timed_texts.pretty_inspect
      timed_text_chunks = trans.chunked_by_time(6)
      #STDERR.puts timed_text_chunks.pretty_inspect
      # transform a little to make it easier to test
      tt_chunks = {}
      timed_text_chunks.each do |ttc|
        tt_chunks[ttc['ts']] = ttc['text']
      end
      tt_chunks.should eq( {
        "00:00:11"=>["That it was in it.", "She was right."],
        "00:00:25"=>["Our picture of the computer. The public picture of the computer keeps", "changing and almost right."], "00:00:35"=>["OK sure", "you can't do anything about it right."],
        "00:00:45"=>["Yeah yeah."]
      })
    end

    it 'updates paid transcript usage' do
      now = DateTime.now

      # test user must own the collection, since usage is limited to billable ownership.
      user.collections << audio_file.item.collection
      audio_file.item.collection.set_owner(user)

      user.usage_for(MonthlyUsage::PREMIUM_TRANSCRIPTS).should eq 0
      extras = { 'original' => audio_file.process_file_url, 'user_id' => user.id }
      t = Tasks::SpeechmaticsTranscribeTask.create!(owner: audio_file, identifier: 'test', extras: extras)

      # audio_file must have the transcript, since transcripts are the billable items.
      audio_file.transcripts << t.process_transcript(response)
      t.user_id.should eq user.id.to_s
      t.extras['entity_id'].should eq user.entity.id
      t.update_premium_transcript_usage(now).should eq 60
      user.usage_for(MonthlyUsage::PREMIUM_TRANSCRIPTS).should eq 60
    end

    it "assigns retail cost for ondemand" do
      audio_file.item.collection.set_owner(user)
      extras = { 'original' => audio_file.process_file_url, 'user_id' => user.id, 'ondemand' => true }
      t = Tasks::SpeechmaticsTranscribeTask.create!(owner: audio_file, identifier: 'test', extras: extras)
      trans = t.process_transcript(response)
      trans.cost_type.should eq Transcript::RETAIL
      trans.retail_cost_per_min.should eq Transcriber.find_by_name('speechmatics').retail_cost_per_min
      trans.cost_per_min.should == Transcriber.find_by_name('speechmatics').cost_per_min
    end

    it 'delineates usage for User vs Org' do
      now = DateTime.now

      # assign user to an org
      org = FactoryGirl.create :organization
      user.organization = org
      user.save!  # because Task will do a User.find(user_id)

      # org must own the collection, since usage is limited to billable ownership.
      audio_file.item.collection.set_owner(org)

      # user must have access to the collection to act on it
      user.collections << audio_file.item.collection

      # user must own the audio_file, since usage is tied to user_id
      audio_file.set_user_id(user.id)
      audio_file.save!  # because usage calculator queries db

      # make sure we start clean
      user.usage_for(MonthlyUsage::PREMIUM_TRANSCRIPTS).should eq 0
      extras = { 'original' => audio_file.process_file_url, 'user_id' => user.id }
      t = Tasks::SpeechmaticsTranscribeTask.create!(owner: audio_file, identifier: 'test', extras: extras)

      # audio_file must have the transcript, since transcripts are the billable items.
      audio_file.transcripts << t.process_transcript(response)

      #STDERR.puts "task.extras = #{t.extras.inspect}"
      #STDERR.puts "audio       = #{audio_file.inspect}"
      #STDERR.puts "org         = #{org.inspect}"
      #STDERR.puts "user        = #{user.inspect}"
      #STDERR.puts "user.entity = #{user.entity.inspect}"
      t.user_id.should eq user.id.to_s
      t.extras['entity_id'].should eq user.entity.id
      t.update_premium_transcript_usage(now).should eq 60

      #STDERR.puts "user.monthly_usages == #{user.monthly_usages.inspect}"
      #STDERR.puts "org.monthly_usages  == #{org.monthly_usages.inspect}"

      # user has non-billable usage
      user.usage_for(MonthlyUsage::PREMIUM_TRANSCRIPT_USAGE).should eq 60

      # user has zero billable usage
      user.usage_for(MonthlyUsage::PREMIUM_TRANSCRIPTS).should eq 0

      # org has all the billable usage
      org.usage_for(MonthlyUsage::PREMIUM_TRANSCRIPTS).should eq 60

      # plan is org's
      audio_file.best_transcript.plan.should == org.plan

    end

    it "should measure usage" do
      task.usage_duration.should eq audio_file.duration
    end

  end

end
