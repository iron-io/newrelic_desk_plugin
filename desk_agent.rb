require 'rest'
require 'yaml'
require 'desk'
require 'iron_cache'

# Requires manual installation of the New Relic plaform gem (platform is in closed beta)
# https://github.com/newrelic-platform/iron_sdk
require 'newrelic_platform'

config = YAML.load_file('config/config.yml')

new_relic = NewRelic::Client.new(:license => config['newrelic']['license'],
                                  :guid => config['newrelic']['guid'],
                                  :version => config['newrelic']['version'])

collector = new_relic.new_collector

## Here is where you'll fill in your own data to be sent to New Relic
desk_config = config['desk']
Desk.configure do |config|
  config.support_email = desk_config['support_email']
  config.subdomain = desk_config['subdomain']
  config.consumer_key = desk_config['key']
  config.consumer_secret = desk_config['secret']
  config.oauth_token = desk_config['oauth_token']
  config.oauth_token_secret = desk_config['oauth_secret']
end

ic = IronCache::Client.new(config['iron'])
cache = ic.cache("newrelic-desk-agent")

# since_hourly so we can do daily, weekly, etc
since_hourly = cache.get("since_hourly")

if since_hourly
  puts "since_hourly: #{since_hourly.value}"
  r = Desk.cases(:since_id=>since_hourly.value)
  r.each do |c|
    p c
  end
  r['results'].each do |c|
    p c
  end
  # first result is the since_hourly, so subtract from it
  total_hourly = r['total'] - 1
  puts "total: #{total_hourly}"

else
  puts "no since_hourly, getting latest case..."
  # let's get mosts recent since_id so we can start this off
  r = Desk.cases
  total_cases = r["total"]
  page = total_cases / r["count"]
  puts "page #{page}"
  r2 = Desk.cases(:page=>page+1)
  r2.each do |c|
    p c
  end
  r2['results'].each do |c|
    p c
  end
  results = r2['results']
  final = results[results.length-1]
  puts "final"
  p final
  since_id = final[:case][:id]
  p since_id
  cache.put("since_hourly", since_id)

end


component = collector.component("Cases Hourly", :duration=>3600)
component.add_metric 'Cases', 'cases', total_hourly + 50
#component.add_metric 'Widget Rate', 'widgets/sec', 5

r = collector.submit()
p r
