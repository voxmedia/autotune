require 'resque'
Resque.redis = ENV['REDIS_URL'] || 'localhost:7777'
Resque.redis.namespace =  ENV['REDIS_NAMESPACE'] || 'resque:AutoTune'
