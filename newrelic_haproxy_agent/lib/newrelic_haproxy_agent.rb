#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "newrelic_plugin"

if RUBY_VERSION < "1.9"
  require 'fastercsv'
else
  # typically, avoid require. In this case we can't use needs' deferred loading because we need to alias CSV
  require 'csv'
  FasterCSV=CSV
end
require 'open-uri'

module NewRelicHaproxyAgent
  
  VERSION = '1.0.1'

  class Agent < NewRelic::Plugin::Agent::Base

    agent_guid   "com.railsware.haproxy"
    agent_config_options :uri, :proxy, :proxy_type, :user, :password
    agent_version NewRelicHaproxyAgent::VERSION
    agent_human_labels("Haproxy") { ident }
    
    attr_reader :ident

    def setup_metrics
      @errors_req=NewRelic::Processor::EpochCounter.new
      @errors_conn=NewRelic::Processor::EpochCounter.new
      @errors_resp=NewRelic::Processor::EpochCounter.new
      @bytes_in=NewRelic::Processor::EpochCounter.new
      @bytes_out=NewRelic::Processor::EpochCounter.new
    end

    def poll_cycle
      if uri.nil?
        raise("URI to HAProxy Stats Required It looks like the URI to the HAProxy stats page (in csv format) hasn't been provided. Please enter this URI in the plugin settings.")
      end
      if proxy_type
        if proxy_type =~ /frontend|backend/i
         @proxy_type = proxy_type.upcase
        end
      end
      found_proxies = []
      possible_proxies = []
      begin
        FasterCSV.parse(open(uri, :http_basic_authentication => [user, password]), :headers => true) do |row|
          next if proxy_type and proxy_type != row["svname"] # ensure the proxy type (if provided) matches
          possible_proxies << row["# pxname"] # used in error message
          next unless proxy.to_s.strip.downcase == row["# pxname"].downcase # ensure the proxy name matches
          # if multiple proxies have the same name, we don't know which to report on.
          if found_proxies.include?(row["# pxname"])
            raise("Multiple proxies have the name '#{proxy}'. Please specify the proxy type (ex: BACKEND or FRONTEND) in the plugin's settings.")
          end
          found_proxies << row["# pxname"]
          report_metric "Requests", "Requests/Minute",             (row['req_rate'].to_i || 0) * 60
          report_metric "Errors/Request", "Errors/Minute",         (@errors_req.process(row['ereq'].to_i) || 0) * 60
          report_metric "Errors/Connection", "Errors/Minute",      (@errors_conn.process(row['econ'].to_i) || 0) * 60
          report_metric "Errors/Response", "Errors/Minute",        (@errors_resp.process(row['eresp'].to_i) || 0) * 60

          report_metric "Bytes/Received", "Bytes/Seconds",          @bytes_in.process(row['bin'].to_i)
          report_metric "Bytes/Sent", "Bytes/Seconds",              @bytes_out.process(row['bout'].to_i)

          report_metric "Sessions/Active", "Sessions",              row['scur']
          report_metric "Sessions/Queued", "Sessions",              row['qcur']
          report_metric "Servers/Active", "Servers",                row['act']
          report_metric "Servers/Backup", "Servers",                row['bck']
          report_metric "ProxyUp", "Status",                        %w(UP OPEN).find {|s| s == row['status']} ? 1 : 0

        end # FasterCSV.parse
      rescue OpenURI::HTTPError
        if $!.message == '401 Unauthorized'
          raise("Authentication Failed. Unable to access the stats page at #{uri} with the username '#{user}' and provided password. Please ensure the username, password, and URI are correct.")
        elsif $!.message != '404 Not Found'
          raise("Unable to find the stats page. The stats page could not be found at: #{uri}.")
        else
          raise
        end
      rescue FasterCSV::MalformedCSVError
        raise("Unable to access stats page. The plugin encountered an error attempting to access the stats page (in CSV format) at: #{uri}. The exception: #{$!.message}\n#{$!.backtrace}")
      end
      if proxy.nil?
        raise("Proxy name required. The name of the proxy to monitor must be provided in the plugin settings. The possible proxies to monitor: #{possible_proxies.join(', ')}")
      elsif found_proxies.empty?
        raise("Proxy not found. The proxy '#{proxy}' #{proxy_type ? "w/proxy type [#{proxy_type}]" : nil} was not found. The possible proxies #{proxy_type ? "for this proxy type" : nil} to monitor: #{possible_proxies.join(', ')}")
      end

    end

  end
  
  # Register and run the agent
  def self.run
    NewRelic::Plugin::Config.config.agents.keys.each do |agent|
      NewRelic::Plugin::Setup.install_agent agent, NewRelicHaproxyAgent
    end

    #
    # Launch the agent (never returns)
    #
    NewRelic::Plugin::Run.setup_and_run
  end

end
