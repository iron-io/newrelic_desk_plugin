`gem install newrelic_platform-0.0.2.gem`

require 'yaml'
require 'desk'
require 'iron_cache'
# Requires manual installation of the New Relic plaform gem (platform is in closed beta)
# https://github.com/newrelic-platform/iron_sdk
require 'newrelic_platform'

# Un-comment to test/debug locally
# def config; @config ||= YAML.load_file('./desk_agent.config.yml'); end

@new_relic = NewRelic::Client.new(:license => config['newrelic']['license'],
                                  :guid => 'io.iron.desk',
                                  :version => config['newrelic']['version'])

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

begin
  @cache = IronCache::Client.new(config['iron']).cache("newrelic-desk-agent")
rescue Exception => err
  abort 'Iron.io credentials are wrong.'
end

# Helpers
def stderr_to_stdout
  $stderr_backup = $stderr unless $stderr_backup
  $stderr = $stdout
end

def restore_stderr
  $stderr = $stderr_backup if $stderr_backup
end

def duration(from, to)
  dur = from ? (to - from).to_i : 3600

  dur > 3600 ? 3600 : dur
end

def up_to(to = nil)
  if to
    @up_to = Time.at(to.to_i).utc
  else
    @up_to ||= Time.now.utc
  end
end

def processed_at(processed = nil)
  if processed
    @cache.put('previously_processed_at', processed.to_i)

    @processed_at = Time.at(processed.to_i).utc
  elsif @processed_at.nil?
    item = @cache.get 'previously_processed_at'
    min_prev_allowed = (up_to - 3600).to_i

    at = if item && item.value.to_i > min_prev_allowed
           item.value
         else
           min_prev_allowed
         end

    @processed_at = Time.at(at).utc
  else
    @processed_at
  end
end

def cases_by_status(cases, status)
  cases.select { |c| c.case.case_status_type == status }
end

# Process
stderr_to_stdout

collector = @new_relic.new_collector
component = collector.component 'Cases'

# Latest cases
latest_cases = []
page = 1
num_results = 0
begin
  r = nil
  begin
    r = Desk.cases(:since_created_at => processed_at.to_i,
                   :max_created_at => up_to.to_i,
                   :page => page,
                   :count => 100)
  rescue Exception => err
    restore_stderr
    if err.message.downcase =~ /oauth/
      abort 'Seems Desk.com credentials are wrong.'
    elsif err.message.downcase =~ /getaddrinfo/
      abort 'Seems Desk.com subdomain is wrong.'
    else
      abort("Error happened while retrieving data from Desk.com. " +
            "Error message: '#{err.message}'.")
    end
  end

  latest_cases |= r.results
  num_results = r.results.count
  page += 1
end while num_results == 100

component.add_metric('Cases/Latest/Total', 'cases', latest_cases.count)
['new', 'open', 'pending', 'resolved', 'closed'].each do |status|
  component.add_metric("Cases/Latest/#{status.capitalize}", 'cases',
                       cases_by_status(latest_cases, status).count)
end

# Overall cases (only new, open and pending)
['new', 'open', 'pending'].each do |status|
  r = Desk.cases(:status => status, :count => 2)

  component.add_metric("Cases/All/#{status.capitalize}",
                       'cases', r.total)
end

component.options[:duration] = duration(processed_at, up_to)

begin
  # Submit data to New Relic
  collector.submit
rescue Exception => err
  restore_stderr
  if err.message.downcase =~ /http 403/
    abort "Seems New Relic's license key is wrong."
  else
    abort("Error happened while sending data to New Relic. " +
          "Error message: '#{err.message}'.")
  end
end

processed_at(up_to)
