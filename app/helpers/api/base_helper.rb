module Api::BaseHelper
  # :nocov:
  def infer_model_name(controller)
    controller.camelize.demodulize.underscore.singularize.intern
  end
  # :nocov:

  # :nocov:
  def inferred_model(controller)
    send(infer_model_name(controller))
  end
  # :nocov:

  def format_time(seconds)
    Time.at(seconds).getgm.strftime('%H:%M:%S')
  end
  module_function :format_time

  def total_hours_on_pua
    hours = Rails.cache.fetch(:pua_total_hours_on_pua, expires_in: 60.minutes) do
      u = User.all
      total_time = u.map {|user| [user.used_unmetered_storage, user.used_metered_storage] }.flatten.sum 
      hours = time_definition(total_time)
    end
    return hours
  end

  def total_time_in_hours
    hours = Rails.cache.fetch(:pua_total_time_in_hours, expires_in: 60.minutes) do
      u = User.all
      total_time = u.map {|user| [user.used_unmetered_storage, user.used_metered_storage] }.flatten.sum
      hours = (total_time / 3600).to_s + "hrs"
    end
    return hours
  end

  def total_public_duration
    Rails.cache.fetch(:pua_total_public_duration_sum, expires_in: 60.minutes) do
      AudioFile.all_public_duration
    end
  end

  def total_public_duration_dhms
    time_definition(total_public_duration)
  end

  def total_private_duration
    Rails.cache.fetch(:pua_total_private_duration_sum, expires_in: 60.minutes) do
      AudioFile.all_private_duration
    end
  end

  def total_private_duration_dhms
    time_definition(total_private_duration)
  end

  def time_definition(total_time)
    if !total_time.is_a? Integer
      total_time = total_time.to_i
    end
    mm, ss = total_time.divmod(60)            
    hh, mm = mm.divmod(60)           
    dd, hh = hh.divmod(24)         
    time = "%d hours (%dd: %dh: %dm: %ds)" % [total_time.div(3600), dd, hh, mm, ss]
    return time
  end  	
  module_function :time_definition
end
