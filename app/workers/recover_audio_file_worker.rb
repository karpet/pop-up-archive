# encoding: utf-8

class RecoverAudioFileWorker
  include Sidekiq::Worker

  # only try 2x to recover, which should be enough.
  sidekiq_options :retry => 2

  def perform(af_id)
    ActiveRecord::Base.connection_pool.with_connection do
      af = AudioFile.find_by_id(af_id)
      begin
        if af
          af.recover!
          af.check_tasks
        end
      rescue StateMachine::InvalidTransition => err
        logger.warn "RecoverAudioFileWorker: StateMachine::InvalidTransition: task: #{af_id}, err: #{err.message}"
      end
      true
    end
  end

end
