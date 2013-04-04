# Desk.com New Relic Agent

**What:** This agent (extended from this [generic SaaS agent](https://github.com/newrelic-platform/ironworker_saas_agent))
runs on the [IronWorker](http://iron.io/worker) platform (another service by [Iron.io](http://iron.io)) and collects data from
Desk.com to send to your own New Relic account.

**Why:** Visualizing your Desk.com data in New Relic is awesome!

**How:** The following instructions describe how to configure and schedule the "IronWorker"
collect data and send to New Relic. It's simple, fast, and **free**!

1. Create free account at [Iron.io](http://iron.io) if you don't already have one
1. Create free account at [New Relic](http://newrelic.com) if you don't already have one
1. Fill in config/config.yml
1. Upload it: `iron_worker --config config/config.yml upload desk_agent`
1. Test it: `iron_worker --config config/config.yml queue desk_agent` - check that it ran successfully at http://hud.iron.io
1. Schedule it: `iron_worker --config config/config.yml schedule desk_agent --run-every 3600`

That's it! You will now see data in New Relic forever!
