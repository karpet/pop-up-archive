require 'spec_helper'

describe ItemSearcher do
  before { StripeMock.start }
  after { StripeMock.stop }

  it "indexes everything" do
    results = Item.__elasticsearch__.search(query: {"match_all"=> {}},"size"=> 0).response
    results.hits.total.should eq 4
  end

  it "can parse params" do
    params = {
      q: 'foo',
      f: { :collection_id => 123 }
    }
    searcher = ItemSearcher.new(params)
    searcher.query_str.should eq params[:q]
    searcher.filters.should eq   params[:f]
  end

  it "strips metacharacters from unparse-able queries" do
    params = {
      q: %{gotcha! you bad <bad> & poor (bankrupt!) string}
    }
    searcher = ItemSearcher.new(params)
    searcher.query_str.should eq %{gotcha you bad bad poor bankrupt string}
  end

  it "parses wildcards" do
    params = {
      q: %{foobar*},
    }
    searcher = ItemSearcher.new(params)
    searcher.query_str.should eq params[:q]
  end

  it "returns aggregations" do
    params = {
      :query => %{*},
      :size => 0
    }
    searcher = ItemSearcher.new(params)
    results=searcher.aggregation_search
    expect(results.aggregations.tags.buckets.find{|b| b[:key] == 'blue'}).to be_truthy
  end

  it "does not include results from others' private collections" do
    current_user = FactoryGirl.create(:user)
    col = FactoryGirl.create(:collection_private, creator_id: current_user.id)
    items=[FactoryGirl.create(:item, title: "New public test item"), FactoryGirl.create(:item_private, title: "Someone elses' Private Test Item"),   FactoryGirl.create(:item_private, title: "My Private Test Item", collection_id: col.id)]
    items.each{|i| i.reindex}
    sleep 1 #necessary for consistent search results
    params = {
      :query => %{test}
    }

    searcher = ItemSearcher.new(params)
    results=searcher.aggregation_search
    result_ids=results.collect{|r| r.id.to_i}
    result_ids.should include items[0].id
    result_ids.should_not include items[1].id
    result_ids.should_not include items[2].id

    searcher = ItemSearcher.new(params, current_user)
    results=searcher.aggregation_search
    result_ids=results.collect{|r| r.id.to_i}
    result_ids.should include items[0].id
    result_ids.should_not include items[1].id
    result_ids.should include items[2].id
  end

end
