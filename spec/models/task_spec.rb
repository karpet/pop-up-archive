require 'spec_helper'

describe Task do
  before { StripeMock.start }
  after { StripeMock.stop }

  it "should allow writing to the extras attributes" do
    task = FactoryGirl.build :task
    task.extras = {'test' => 'test value'}
    task.save
  end

  it 'should persist the extras attributes' do
    task = FactoryGirl.create :task
    task.extras = {'test' => 'test value'}
    task.save

    Task.find(task.id).extras['test'].should eq 'test value'
  end

  it 'should persist the owner.storage.id' do
    task = FactoryGirl.create :task
    task.storage_id.should eq task.owner.storage.id
  end

  it 'should return type_name' do
    task = FactoryGirl.create :task
    task.type_name.should eq 'task'

    class Tasks::GoodTestTask < Task; end;
    Tasks::GoodTestTask.new.type_name.should eq 'good_test'
  end

  it 'should get the original from the owner' do
    task = FactoryGirl.create :task
    task.original.should eq task.owner.process_file_url
  end

  describe 'fixer call backs' do
    before {
      @task = FactoryGirl.build :task
      @task.extras['call_back_url'] = "#{ENV['SERVER_HOSTNAME']}/test"
      @task.save!
      @task.reload
    }

    it "should default a call_back_token" do
      @task.extras['cbt'].should_not be_nil
      @task.call_back_token.should eq @task.extras['cbt']
    end

    it 'should get the call_back_url from extras' do
      @task.call_back_url.should eq "#{ENV['SERVER_HOSTNAME']}/test?cbt=#{@task.extras['cbt']}"
    end

    it 'should get the call_back_url from owner' do
      @task.extras.delete('call_back_url')
      @task.call_back_url.should end_with(".popuparchive.com/fixer_callback/files/audio_file/#{@task.owner.id}?cbt=#{@task.extras['cbt']}")
    end

  end

  describe "manage results" do

    before {
      @task = FactoryGirl.create :task
      @task.results = {"status"=>"complete", "message"=>"analysis complete", "info"=>{"services"=>["open_calais", "yahoo_content_analysis"], "stats"=>{"topics"=>0, "tags"=>0, "entities"=>7, "relations"=>0, "locations"=>2}}, "logged_at"=>"2013-11-11T15:38:19Z"}
      @task.save!
      @task.reload
    }

    it 'should save results' do
      @task.results.keys.sort.should eq ["info", "logged_at", "message", "status"]
      @task.results[:status].should eq "complete"
    end

    it 'should be able to access results as indifferent access' do
      @task.results[:info][:stats][:locations].should eq 2
      @task.results['info']['stats']['locations'].should eq 2
    end

  end

  describe "manage stuck definition" do

    it "should identify work window" do
      @task = FactoryGirl.create :task
      # assume window is less than 1 day but test it so we fail explicitly
      Task.work_window.should be > 1.day.ago
      @task.created_at = 1.day.ago # do not save or it will overwrite
      @task.outside_work_window?().should be_truthy
      @task.stuck?().should be_truthy
    end
  end

end
