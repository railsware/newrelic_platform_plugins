#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "newrelic_plugin"

require 'resque'
require 'redis'

module NewRelicResqueAgent
  
  VERSION = '1.0.0'

  class Agent < NewRelic::Plugin::Agent::Base

    agent_guid "com.railsware.resque"
    agent_config_options :redis, :namespace
    agent_version NewRelicResqueAgent::VERSION
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
  
  # Register and run the agent
  def self.run
    NewRelic::Plugin::Config.config.agents.keys.each do |agent|
      NewRelic::Plugin::Setup.install_agent agent, NewRelicResqueAgent
    end

    #
    # Launch the agent (never returns)
    #
    NewRelic::Plugin::Run.setup_and_run
  end

end