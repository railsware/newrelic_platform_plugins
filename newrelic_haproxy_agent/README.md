## New Relic Haproxy Extension

### Instructions for running the Haproxy extension agent

1. run `bundle install` to install required gems
2. Copy `config/newrelic_plugin.yml.example` to `config/newrelic_plugin.yml`
3. Edit `config/newrelic_plugin.yml` and replace "YOUR_LICENSE_KEY_HERE" with your New Relic license key
4. Edit the `config/newrelic_plugin.yml` file and add the URI of the haproxy CSV stats url
5. Execute `ruby newrelic_haproxy_agent.rb`
6. Go back to the Extensions list and after a brief period you will see the extension listed
