# Desk.com New Relic Agent

## What

This agent (extended from this [generic SaaS agent](https://github.com/newrelic-platform/ironworker_saas_agent))
runs on the [IronWorker](http://iron.io/worker) platform (another service by [Iron.io](http://iron.io)) and collects data from
Desk.com to send to your own New Relic account.

## Why

Visualizing your Desk.com data in New Relic is awesome!

## How

The following instructions describe how to configure and schedule the "IronWorker"
collect data and send to New Relic. It's simple, fast, and **free**!

First, let's get setup:

1. Create free account at [Iron.io](http://iron.io) if you don't already have one
1. Create free account at [New Relic](http://newrelic.com) if you don't already have one

Now the fun stuff.

<!---
 NOT READY YET

### Easiest Way

Can do it all from the Iron.io UI, no code, no files, etc.

1. Log in to [HUD](https://hud.iron.io)
1. Click IronWorker on one of your projects.
1. Click Upload Turn Key Worker.
1. Enter `https://github.com/newrelic-platform/ironio_desk_extension/blob/master/desk_agent.worker` in the worker URL.
1. Fill in the config
1. Click upload
1. Click queue to run it once to test it
1. Click schedule to schedule it
--->

### Easiest way

Need the iron_worker_ng gem, but you don't need to clone the repo or anything like that.

1. `gem install iron_worker_ng`
1. Copy and paste contents of this file: https://github.com/newrelic-platform/ironio_desk_extension/blob/master/desk_agent.config.yml into a file on your computer called `config.yml` and fill it in with your credentials.
1. Upload it: `iron_worker upload --config config.yml https://github.com/newrelic-platform/ironio_desk_extension/blob/master/desk_agent.worker --worker-config config.yml`
1. Test it: `iron_worker queue --config config.yml desk_agent --wait` - can also check task status at http://hud.iron.io
1. Schedule it: `iron_worker schedule --config config.yml desk_agent --run-every 3600`

### Hardest way

Well, it's not that hard and you can customize the worker to your liking.

1. `gem install iron_worker_ng`
1. Clone this repository
1. Copy desk_agent.config.yml to config.yml, then fill it in with your information.
1. Upload it: `iron_worker upload --config config.yml desk_agent --worker-config config.yml`
1. Test it: `iron_worker queue --config config.yml desk_agent --wait` - You can also check task status at http://hud.iron.io
1. Schedule it: `iron_worker schedule --config config.yml desk_agent --run-every 3600`

That's it! You will now see data in New Relic forever!
