#!/usr/bin/env ruby

# Monitors Resque, a library for processing background jobs, reporting the following data for a specified instance:
#  * Number of working workers
#  * Pending jobs number
#  * Total failed jobs number
#  * Ques number
#  * Number of workers
#  * Number of processed jobs
#
# Compatibility 
# -------------
# Requires the resque and redis gems


require "rubygems"
require "bundler/setup"
require "newrelic_plugin"

require 'resque'
require 'redis'

#
#
# NOTE: Please add the following lines to your Gemfile:
#     gem "newrelic_plugin", git: "git@github.com:newrelic-platform/newrelic_plugin.git"
#
#
# Note: You must have a config/newrelic_plugin.yml file that
#       contains the following information in order to use
#       this Gem:
#
#       newrelic:
#         # Update with your New Relic account license key:
#         license_key: 'put_your_license_key_here'
#         # Set to '1' for verbose output, remove for normal output.
#         # All output goes to stdout/stderr.
#         verbose: 1
#       agents:
#         resque:
#            # Redis connection string: 'hostname:port' or 'hostname:port:db' or 'redis://user:password@hostname:port:db'
#            redis: user:password@localhost:6379


module ResqueAgent

  class Agent < NewRelic::Plugin::Agent::Base

    agent_guid "6e5e4fe8d943e82ee498e4d3618544e2e860f6c1"
    agent_config_options :redis, :namespace
    agent_human_labels("Resque") { redis }

    def setup_metrics
      @working      = NewRelic::Processor::EpochCounter.new
      @pending      = NewRelic::Processor::EpochCounter.new
      @total_failed = NewRelic::Processor::EpochCounter.new
      @queues       = NewRelic::Processor::EpochCounter.new
      @workers      = NewRelic::Processor::EpochCounter.new
      @processed    = NewRelic::Processor::EpochCounter.new
    end

    def poll_cycle
      if redis.nil?
        raise "Redis connection URL "
      end

      begin
        Resque.redis = redis
        Resque.redis.namespace = namespace unless namespace.nil?
        info = Resque.info

        report_metric "Working", "Workers",   info[:working]
        report_metric "Pending", "Jobs",      info[:pending]
        report_metric "Total Failed", "Jobs", info[:total_failed]
        report_metric "Queues", "Queues",     info[:queues]
        report_metric "Workers", "Workers",   info[:workers]
        report_metric "Processed", "Jobs",    info[:total_failed]

      rescue Redis::TimeoutError
        raise 'Redis server timeout'
      rescue  Redis::CannotConnectError, Redis::ConnectionError
        raise 'Could not connect to redis'
      rescue Errno::ECONNRESET
        raise 'Connection was reset by peer'
      end
    end

  end
  NewRelic::Plugin::Setup.install_agent :resque, ResqueAgent

  #
  # Launch the agent (never returns)
  #
  NewRelic::Plugin::Run.setup_and_run

end