class TimedText < ActiveRecord::Base
  attr_accessible :start_time, :end_time, :text, :confidence, :speaker_id
  belongs_to :transcript
  belongs_to :speaker

  delegate :audio_file, to: :transcript

  after_save :refresh_index

  def refresh_index
    self.transcript.update_item
  end

  def as_json(options = :sigil)
    if options == :sigil
      {audio_file_id: transcript.audio_file_id, confidence: confidence, text: text, start_time: start_time, end_time: end_time }
    else
      super
    end
  end

  def as_indexed_json
    as_json.tap do |json|
      json[:transcript] = json.delete :text
    end
  end

  def offset_as_ts
    Time.at(start_time).getgm.strftime('%H:%M:%S')
  end

  def previous_tt
    timed_texts=transcript.timed_texts.sort {|a, b| a.start_time <=> b.start_time}
    sorted_ids= timed_texts.map(&:id)
    index = sorted_ids.index(id)
    prev_id=sorted_ids[index - 1]
    TimedText.find(prev_id)
  end

end
