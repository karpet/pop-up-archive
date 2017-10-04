require 'spec_helper'

describe ProcessTaskWorker do
  before { StripeMock.start }
  #before { StripeMock.start && StripeMock.toggle_debug(true) }
  after { StripeMock.stop }

  it "process a task" do
    @task = FactoryGirl.create :analyze_task
    @worker = ProcessTaskWorker.new
    Task.should_receive(:find_by_id).and_return(@task)
    @task.should_receive(:process).and_return(true)
    @worker.perform(@task.id).should eq true
  end

end
