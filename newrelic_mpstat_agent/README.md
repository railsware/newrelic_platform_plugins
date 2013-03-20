## New Relic Mpstat Extension

### Instructions for running the Mpstat extension agent

Requires the mpstat command, usually provided by the sysstat package.

1. run `bundle install` to install required gems
2. Copy `config/newrelic_plugin.yml.example` to `config/newrelic_plugin.yml`
3. Edit `config/newrelic_plugin.yml` and replace "YOUR_LICENSE_KEY_HERE" with your New Relic license key
4. Edit the `config/newrelic_plugin.yml` file and add path to 'mpstat' command
5. Execute `ruby newrelic_mpstat_agent.rb`
6. Go back to the Extensions list and after a brief period you will see the extension listed
