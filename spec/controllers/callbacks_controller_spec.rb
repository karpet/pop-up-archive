require 'spec_helper'
describe CallbacksController do
  extend ControllerMacros

  before { StripeMock.start }
  after { StripeMock.stop }

  before :each do
    request.accept = "application/json"
  end

  describe "test callback" do
    it "should get 200 for tester route" do
      post 'tester'
      response.status.should eq 200
    end
  end

  describe "POST 'create'" do
    before :each do
      @task = FactoryGirl.create :add_to_amara_task, extras: {'video_id' => 'abcdefg'}

    end

    it "gets random callback from amara" do
      post 'amara', {"video_id"=>"abcdefg", "event"=>'subs-random'}
      response.code.should eq "200"
      response.should be_success
    end

    it "gets new callback from amara" do
      post 'amara', {"video_id"=>"abcdefg", "event"=>'subs-new'}
      response.code.should eq "202"
      response.should be_success
    end

    it "gets approved callback from amara" do
      post 'amara', {"video_id"=>"abcdefg", "event"=>'subs-approved'}
      response.code.should eq "202"
      response.should be_success
    end

  end

  describe "Stripe callbacks" do

    self.use_transactional_fixtures = false  # so controller actions are not isolated

    it "logs event as ActiveAdminComent on User" do
      # prep fixtures
      user = FactoryGirl.create :user
      # use explicit customer id to avoid confusion
      user.customer_id = 'test_stripe_customer_123'
      user.save!
      stripe_event = {
        'data' => {
          'object' => {
            'customer' => user.customer_id,
          }
        },
        'type' => 'customer.subscription.updated',
      }
      user.save!
 
      # test response and that user is changed in db
      post 'stripe_webhook', stripe_event
      response.code.should eq "200"
      comment = user.active_admin_comments.first
      comment_body = JSON.parse(comment.body)
      #STDERR.puts "comment==#{comment.inspect}"
      #STDERR.puts "comment_body==#{comment_body}"
      comment_body.should eq stripe_event
    end

  end

  describe "Task callbacks" do

    self.use_transactional_fixtures = false  # so controller actions are not isolated

    it "should log fixer callback" do
      af = FactoryGirl.create :audio_file
      af.check_tasks
      task = af.tasks.first
      fixer_job = { 'job' => { 'id' => 'abc123', }, 'result_details' => { 'status' => 'complete' } }
      post 'fixer', model_name: 'task', id: task.id, task: fixer_job
      response.status.should eq 202
      task.reload
      task.extras['job_id'].should eq fixer_job['job']['id']
    end

    it "should log voicebase callback", :type => :request do
      af = FactoryGirl.create :audio_file
      task = af.start_voicebase_transcribe_job(af.user, 'ts_paid')
      vb_payload = { 'media' => { 'mediaId' => 'abc123' }, 'callback' => { 'event' => { 'status' => 'complete' } } }
      task.extras['job_id'] = vb_payload['media']['mediaId']
      task.set_voicebase_defaults
      task.save!
      post task.voicebase_call_back_url, vb_payload.to_json, { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' }
      response.status.should eq 202
      task.reload
      task.extras['job_status'].should eq 'complete'
    end

    it "should log speechmatics callback", :type => :request do
      af = FactoryGirl.create :audio_file
      task = af.start_speechmatics_transcribe_job(af.user, 'ts_paid')
      task.set_speechmatics_defaults
      task.save!
      post task.speechmatics_call_back_url, id: 'abc123'
      response.status.should eq 202
      task.reload
      task.extras['sm_job_id'].should eq 'abc123'
    end

  end
end
