class Transcriber < ActiveRecord::Base

  # IMPORTANT: cost_per_min is in 1000ths of a dollar, not 100ths (cents)
  # so e.g. $0.062 is recorded as 62
  attr_accessible :name, :cost_per_min, :url, :description, :retail_cost_per_min

  has_many :transcripts

  after_commit :invalidate_caches, on: :update

  def self.ids_for_type(usage_type)
    if usage_type == 'basic' or usage_type == MonthlyUsage::BASIC_TRANSCRIPTS or usage_type == MonthlyUsage::BASIC_TRANSCRIPT_USAGE
      [ self.basic.id ]
    else
      [ self.speechmatics.id, self.voicebase.id ]
    end
  end

  def self.basic
    @_basic ||= self.find_by_name('google_voice')
  end

  def self.premium
    @_premium ||= self.get_premium
  end

  def self.get_premium
    if ENV['PREMIUM_TRANSCRIBER'] && ENV['PREMIUM_TRANSCRIBER'] == "voicebase"
      self.voicebase
    else
      self.speechmatics
    end
  end

  def self.speechmatics
    @_speechmatics ||= self.find_by_name('speechmatics')
  end

  def self.voicebase
    @_voicebase ||= self.find_by_name('voicebase')
  end

  # call this whenever making price changes
  def invalidate_caches
    @_basic = nil
    @_premium = nil
  end

  # returns float for cost of N seconds of transcription.
  # NOTE cost_per_min is wholesale cost, not retail cost.
  def wholesale_cost(seconds)
    mins = seconds.to_i.fdiv(60)
    c = (cost_per_min.to_f * mins.to_f) / 1000
    c.round(2)
  end

  # returns float for retail cost of N seconds of transcription.
  def retail_cost(seconds)
    mins = seconds.to_i.fdiv(60)
    c = (retail_cost_per_min.to_f * mins.to_f) / 1000
    c.round(2)
  end

end
