## New Relic Resque monitoring Plugin

The New Relic Resque Plugin enables monitoring of Resque, a library for processing background jobs, reporting the following data for a specified instance:

* Number of working workers
* Pending jobs number
* Total failed jobs number
* Queues number
* Number of workers
* Number of processed jobs

### Requirements

The Resque monitoring Plugin for New Relic requires the following:

* A New Relic account. Signup for a free account at http://newrelic.com
* You need a host to install the plugin on that is able to poll the desired Redis server. That host also needs Ruby (tested with 1.8.7, 1.9.3), and support for rubygems.

### Instructions for running the Resque agent

1. Install this gem from RubyGems:

    `sudo gem install newrelic_resque_agent`

2. Install config, execute

    `sudo newrelic_resque_agent install` - it will create `/etc/newrelic/newrelic_resque_agent.yml` file for you.

3. Edit the `/etc/newrelic/newrelic_resque_agent.yml` file generated in step 2.

    3.1. replace `YOUR_LICENSE_KEY_HERE` with your New Relic license key. Your license key can be found under Account Settings at https://rpm.newrelic.com, see https://newrelic.com/docs/subscriptions/license-key for more help.

    3.2. add the Redis connection string: 'hostname:port' or 'hostname:port:db' or 'redis://user:password@hostname:port:db'

4. Execute

    `newrelic_resque_agent run`

5. Go back to the Plugins list and after a brief period you will see the Resque Plugin listed in your New Relic account


## Keep this process running

You can use services like these to manage this process and run it as a daemon.

- [Upstart](http://upstart.ubuntu.com/)
- [Systemd](http://www.freedesktop.org/wiki/Software/systemd/)
- [Runit](http://smarden.org/runit/)
- [Monit](http://mmonit.com/monit/)

Also you can use [foreman](https://github.com/ddollar/foreman) for daemonization.

Foreman can be useful if you want to use [Heroku](https://www.heroku.com/) for run your agent. Just add Procfile and push to Heroku.

`monitor_daemon: newrelic_resque_agent run -c config/newrelic_plugin.yml`
