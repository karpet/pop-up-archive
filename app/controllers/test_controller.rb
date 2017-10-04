class TestController < ApplicationController

  rescue_from ActiveRecord::RecordNotFound, :with => :not_found
  rescue_from Elasticsearch::Transport::Transport::Errors::NotFound, :with => :not_found
  rescue_from ActionController::UrlGenerationError, :with => :not_found

  def show
    raise ActiveRecord::RecordNotFound, 'not found'
  end

end
