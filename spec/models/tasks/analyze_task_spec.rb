require 'spec_helper'

describe Tasks::AnalyzeTask do

  before { StripeMock.start }
  after { StripeMock.stop }

  before(:each) do 
    @audio_file = FactoryGirl.create :audio_file
    @task = Tasks::AnalyzeTask.new(owner: @audio_file, identifier: 'analysis')
  end

  it "should create entities from content analysis" do
    analysis = '{"language":"","topics":[{"name":"Business and finance","score":0.952,"original":"Business_Finance"},{"name":"Hospitality and recreation","score":0.937,"original":"Hospitality_Recreation"},{"name":"Law and crime","score":0.868,"original":"Law_Crime"},{"name":"Entertainment and culture","score":0.587,"original":"Entertainment_Culture"},{"name":"Media","score":0.742268,"original":"Media"}],"tags":[{"name":"cashola","score":0.5},{"name":"flarb","score":0.5}],"entities":[],"relations":[],"locations":[]}'
    @task.process_analysis(analysis)
    @audio_file.item.entities.count.should eq 6
  end

  it "should not create dupe entities from content analysis" do
    analysis = '{"language":"","topics":[{"name":"Business and finance","score":0.952,"original":"Business_Finance"},{"name":"Hospitality and recreation","score":0.937,"original":"Hospitality_Recreation"},{"name":"Law and crime","score":0.868,"original":"Law_Crime"},{"name":"Entertainment and culture","score":0.587,"original":"Entertainment_Culture"},{"name":"Media","score":0.742268,"original":"Media"}],"tags":[{"name":"cashola","score":0.5},{"name":"flarb","score":0.5}],"entities":[],"relations":[],"locations":[]}'
    @task.process_analysis(analysis)
    @task.process_analysis(analysis)
    @audio_file.item.entities.count.should eq 6
  end
  
  it "should check the controlled vocabulary" do
    analysis = '{"language":"","topics":[{"name":"Business and finance","score":0.952,"original":"Business_Finance"},{"name":"Hospitality and recreation","score":0.937,"original":"Hospitality_Recreation"},{"name":"Law and crime","score":0.868,"original":"Law_Crime"},{"name":"Entertainment and culture","score":0.587,"original":"Entertainment_Culture"},{"name":"Media","score":0.742268,"original":"Media"}],"tags":[{"name":"cashola","score":0.5},{"name":"flarb","score":0.5}, {"name":"frank sinatra: live at melbourne festival hall","score":0.5}],"entities":[],"relations":[],"locations":[]}'
    @task.process_analysis(analysis)
    @audio_file.item.entities.to_json.should_not include("frank sinatra: live at melbourne festival hall")
    @audio_file.item.entities.to_json.should_not include("flarb") 
  end

  it "should integrate frequency information" do
    json = '[{"start_time":0,"end_time":9,"text":"from Wednesday January 30th 2013 the following is a replay of the radio doctor daily session in North Carolina House of Representatives","confidence":0.90355223},{"start_time":8,"end_time":17,"text":"tractor seat visitors","confidence":0.8770266},{"start_time":9,"end_time":12,"text":"san francisco","confidence":0.90355223},{"start_time":13,"end_time":17,"text":"San Francisco","confidence":0.8770266},{"start_time":18,"end_time":25,"text":"Monaco","confidence":0.8770266}]'
    # json = '[]'
    trans = @audio_file.transcripts.build(language: 'en-US', identifier: "identifier", start_time: 0, end_time: 25)
    trans_json = JSON.parse(json)
    trans_json.each do |row|
      tt = trans.timed_texts.build({
        start_time: row['start_time'],
        end_time:   row['end_time'],
        confidence: row['confidence'],
        text:       row['text']
      })
    end

    analysis = '{"language":"","topics":[{"name":"Hospitality and recreation","score":0.937,"original":"Hospitality_Recreation"}],"tags":[{"name":"tractor","score":1.0}],"entities":[],"relations":[],"locations":[{"name":"San Francisco","score":0.5}, {"name": "Monaco", "score":0.5}]}' 
    @task.process_analysis(analysis)
    #filter infrequent locations
    @audio_file.item.entities.to_json.should include("San Francisco")
    @audio_file.item.entities.to_json.should_not include("Monaco")
    #recalculate score based on frequency
    @audio_file.item.entities.select{ |e| e.name == 'Hospitality and recreation' }[0].score.should eq 0.937
    @audio_file.item.entities.select{ |e| e.name == 'tractor' }[0].score.should eq 1.0
    @audio_file.item.entities.select{ |e| e.name == 'San Francisco' }[0].score.should eq 1.0
  end

end