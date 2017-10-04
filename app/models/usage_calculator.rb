class UsageCalculator

  attr_accessor :entity, :dtim

  MONTHLY_USE_METHOD = {
    MonthlyUsage::PREMIUM_TRANSCRIPTS      => :calculate_billable,
    MonthlyUsage::BASIC_TRANSCRIPTS        => :calculate_billable,
    MonthlyUsage::PREMIUM_TRANSCRIPT_USAGE => :calculate_usage,
    MonthlyUsage::BASIC_TRANSCRIPT_USAGE   => :calculate_usage,
  }

  def initialize(entity, dtim)
    @entity = entity
    @dtim = dtim
  end

  def calculate(usage_type)

    # finds all the transcripts for the time period and returns the total seconds and cost
    #puts "calculate usage for entity #{entity} for #{dtim} transcriber #{transcriber.id} type #{usage_type}"
    # whether the calculation is billable or not triggers which method is called on the @entity.
    if MONTHLY_USE_METHOD.has_key?(usage_type)
      methd = MONTHLY_USE_METHOD[usage_type]
      #STDERR.puts("calculating with #{methd}")
      self.send(methd, usage_type)
    else
      raise "No calculation method defined for usage type #{usage_type}"
    end

  end

  def calculate_billable(usage_type)

    # finds all the transcripts for the time period and returns the total seconds and cost
    #puts "calculate usage for entity #{entity} for #{dtim} transcriber #{transcriber.id} type #{usage_type}"
    report = @entity.transcripts_billable_for_month_of(@dtim, Transcriber.ids_for_type(usage_type))
    @entity.update_usage_for(usage_type, report, @dtim)
    #STDERR.puts "calculate_billable for entity #{entity} for #{dtim} transcriber #{transcriber.id} type #{usage_type} = #{report.inspect}"
    report[:seconds]

  end

  def calculate_usage(usage_type)

    report = @entity.transcripts_usage_for_month_of(@dtim, Transcriber.ids_for_type(usage_type))
    @entity.update_usage_for(usage_type, report, @dtim)
    #STDERR.puts "calculate_usage for entity #{entity} for #{dtim} transcriber #{transcriber.id} type #{usage_type} = #{report.inspect}"
    report[:seconds]

  end 

end
