if Rails.env == 'development'
  require 'rack-mini-profiler'
  require 'flamegraph'
  require 'fast_stack'
  
  Rack::MiniProfilerRails.initialize!(Rails.application)
end
