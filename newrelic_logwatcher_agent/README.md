## New Relic Logwatcher Extension

### Instructions for running the Logwatcher extension agent

1. run `bundle install` to install required gems
2. Copy `config/newrelic_plugin.yml.example` to `config/newrelic_plugin.yml`
3. Edit `config/newrelic_plugin.yml` and replace "YOUR_LICENSE_KEY_HERE" with your New Relic license key
4. Edit the `config/newrelic_plugin.yml` file and add Full path to the the log file
5. Execute `ruby newrelic_logwatcher_agent.rb`
6. Go back to the Extensions list and after a brief period you will see the extension listed
