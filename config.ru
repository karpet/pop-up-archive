# This file is used by Rack-based servers to start the application.
# if ENV['RAILS_ENV'] == 'production' || ENV['RAILS_ENV'] == 'staging'
#   # Unicorn self-process killer
#   require 'unicorn/worker_killer'
#
#   # Max requests per worker
#   use Unicorn::WorkerKiller::MaxRequests, 3072, 4096
#
#   # Max memory size (RSS) per worker
#   use Unicorn::WorkerKiller::Oom, (192*(1024**2)), (256*(1024**2))
# end

require ::File.expand_path('../config/environment',  __FILE__)
use Rack::Static, :urls => ['/carrierwave'], :root => 'tmp' # adding this line
run PopUpArchive::Application