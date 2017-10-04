require 'spec_helper'

describe Tasks::VoicebaseTranscribeTask do

  before { StripeMock.start }
  after { StripeMock.stop }

  let(:user) { FactoryGirl.create :user }
  let(:audio_file) { FactoryGirl.create :audio_file_private, user_id: user.id }
  let(:task) { Tasks::VoicebaseTranscribeTask.new(owner: audio_file, extras: {'user_id' => user.id}) }

 let(:response) {
    m = Hashie::Mash.new
    m.words =[
      {"w"=>"Yeah","e"=>4270,"s"=>4040,"c"=>0.729,"p"=>0},
      {"w"=>"this","e"=>4360,"s"=>4270,"c"=>0.573,"p"=>1},
      {"w"=>"is","e"=>5530,"s"=>4360,"c"=>0.672,"p"=>2},
      {"w"=>"great","e"=>5670,"s"=>5530,"c"=>0.662,"p"=>3},
      {"w"=>".","e"=>7080,"s"=>5670,"c"=>0.0,"p"=>4,"m"=>"punc"},
      {"w"=>"Eat","e"=>8010,"s"=>7080,"c"=>0.501,"p"=>5},
      {"w"=>"our","e"=>13380,"s"=>8010,"c"=>0.538,"p"=>6},
      {"w"=>"hearts","e"=>13630,"s"=>13380,"c"=>0.697,"p"=>7},
      {"w"=>"are","e"=>14540,"s"=>13630,"c"=>0.795,"p"=>8},
      {"w"=>"community","e"=>15200,"s"=>14540,"c"=>0.501,"p"=>9},
      {"w"=>"library","e"=>15380,"s"=>15200,"c"=>0.501,"p"=>10},
      {"w"=>".","e"=>17200,"s"=>15380,"c"=>0.0,"p"=>11,"m"=>"punc"},
      {"w"=>"Possibly","e"=>17520,"s"=>17200,"c"=>0.501,"p"=>12},
      {"w"=>"than","e"=>17620,"s"=>17520,"c"=>0.504,"p"=>13},
      {"w"=>"that","e"=>18410,"s"=>17620,"c"=>0.616,"p"=>14},
      {"w"=>"library","e"=>18440,"s"=>18410,"c"=>0.509,"p"=>15},
      {"w"=>".","e"=>19890,"s"=>18440,"c"=>0.0,"p"=>16,"m"=>"punc"}
    ]
    m.diarization =[
      {"speakerLabel"=>"S127","band"=>"S","start"=>5830,"length"=>1590,"gender"=>"F","env"=>"U"},
      {"speakerLabel"=>"S1","band"=>"S","start"=>13970,"length"=>1680,"gender"=>"F","env"=>"U"},
      {"speakerLabel"=>"S1","band"=>"S","start"=>16400,"length"=>2620,"gender"=>"F","env"=>"U"},
    ]
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
      task.set_voicebase_defaults
      task.call_back_url.should eq "http://test.popuparchive.com/voicebase_callback/files/task/#{task.extras['public_id']}"
    end

    it "processes transcript result" do

      trans = task.process_transcript(response)
      #STDERR.puts trans.timed_texts.pretty_inspect
      timed_text_chunks = trans.chunked_by_time(6)
      #STDERR.puts timed_text_chunks.pretty_inspect
      # transform a little to make it easier to test
      tt_chunks = {}
      timed_text_chunks.each do |ttc|
        tt_chunks[ttc['ts']] = ttc['text']
      end
      tt_chunks.should eq( {
        "00:00:04" => ["Yeah this is great.", "Eat", "our"],
        "00:00:13" => ["hearts are community library.", "Possibly than that library."]
      })
    end

    it 'updates paid transcript usage' do
      now = DateTime.now
      user.collections << audio_file.item.collection
      # test user must own the collection, since usage is limited to billable ownership.
      audio_file.item.collection.set_owner(user)

      user.usage_for(MonthlyUsage::PREMIUM_TRANSCRIPTS).should eq 0
      extras = { 'original' => audio_file.process_file_url, 'user_id' => user.id }
      t = Tasks::VoicebaseTranscribeTask.create!(owner: audio_file, identifier: 'test', extras: extras)

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
      t = Tasks::VoicebaseTranscribeTask.create!(owner: audio_file, identifier: 'test', extras: extras)
      trans = t.process_transcript(response)
      trans.cost_type.should eq Transcript::RETAIL
      trans.retail_cost_per_min.should eq Transcriber.find_by_name('voicebase').retail_cost_per_min
      trans.cost_per_min.should == Transcriber.find_by_name('voicebase').cost_per_min
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
      t = Tasks::VoicebaseTranscribeTask.create!(owner: audio_file, identifier: 'test', extras: extras)

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
