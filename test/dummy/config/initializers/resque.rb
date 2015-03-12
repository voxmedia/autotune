require 'resque'
Resque.redis = ENV['REDIS_SERVER'] || 'localhost:6379'
Resque.redis.namespace =  ENV['REDIS_NAMESPACE'] || 'resque:AutoTune'
