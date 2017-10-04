require 'spec_helper'

describe IndexerWorker, elasticsearch: true do
  before { StripeMock.start }
  after { StripeMock.stop }

  before do
    Item.__elasticsearch__.create_index! index: Item.index_name
    Item.import force: true, refresh: true
  end

  after do
    Item.__elasticsearch__.client.indices.delete index: Item.index_name
  end

  it "creates index" do
    @item = FactoryGirl.create :item
    @worker = IndexerWorker.new
    @worker.perform(:index, @item.class.to_s, @item.id)["created"].should eq true
  end

  it "updates index" do
    @item = FactoryGirl.create :item
    @worker = IndexerWorker.new
    @worker.perform(:index, @item.class.to_s, @item.id)["created"].should eq true
    @worker.perform(:update, @item.class.to_s, @item.id)["_version"].should eq 2
  end

  it "deletes index" do
    @item = FactoryGirl.create :item
    @worker = IndexerWorker.new
    @worker.perform(:index, @item.class.to_s, @item.id)["created"].should eq true
    @worker.perform(:delete, @item.class.to_s, @item.id)["found"].should eq true
  end
end
