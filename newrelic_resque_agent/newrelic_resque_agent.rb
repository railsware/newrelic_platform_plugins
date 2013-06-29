#!/usr/bin/env ruby
$stdout.sync = true

# Monitors Resque, a library for processing background jobs, reporting the following data for a specified instance:
#  * Number of working workers
#  * Pending jobs number
#  * Total failed jobs number
#  * Queues number
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

    agent_guid "com.railsware.resque"
    agent_config_options :redis, :namespace
    agent_version '0.0.3'
    agent_human_labels("Resque") { ident }
    
    attr_reader :ident

    def setup_metrics
      @total_failed = NewRelic::Processor::EpochCounter.new
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
        
        report_metric "Workers/Working", "Workers",           info[:working]
        report_metric "Workers/Total", "Workers",             info[:workers]
        report_metric "Jobs/Pending", "Jobs",                 info[:pending]
        report_metric "Jobs/Rate/Processed", "Jobs/Second",        @processed.process(info[:processed])
        report_metric "Jobs/Rate/Failed", "Jobs/Second",           @total_failed.process(info[:failed])
        report_metric "Queues", "Queues",                     info[:queues]
        report_metric "Jobs/Failed", "Jobs",                  info[:failed] || 0
        
        

      rescue Redis::TimeoutError
        raise 'Redis server timeout'
      rescue  Redis::CannotConnectError, Redis::ConnectionError
        raise 'Could not connect to redis'
      rescue Errno::ECONNRESET
        raise 'Connection was reset by peer'
      end
    end

  end
  
  NewRelic::Plugin::Config.config.agents.keys.each do |agent|
    NewRelic::Plugin::Setup.install_agent agent, ResqueAgent
  end

  #
  # Launch the agent (never returns)
  #
  NewRelic::Plugin::Run.setup_and_run

end