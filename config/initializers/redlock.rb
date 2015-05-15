redlock = Redlock::Client.new([$redis])

Thread.new do
  loop do
    redlock.lock('master', 45100) do |locked|
      if locked
        counter = 1
        45.times do
          $redis.publish 'heartbeat', counter.to_json unless $redis.nil?
          counter += 1
          sleep 1
        end
      else
        sleep 10000
      end
    end
  end
end
