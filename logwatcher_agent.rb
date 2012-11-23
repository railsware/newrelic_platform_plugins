#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"
require "newrelic_plugin"

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
#         logwatcher:
#            # Full path to the the log file
#            log_path: tmp.log
#            # Returns the number of matches for this term. Use Linux Regex formatting.
#            # Default: "[Ee]rror"
#            term: "[Ee]rror"
#            # Provide any options to pass to grep when running. 
#            # For example, to count non-matching lines, enter 'v'. 
#            # Use the abbreviated format ('v' and not 'invert-match').
#            grep_options:
#
#



module NewRelic::Processor
  class DiffRate<NewRelic::Plugin::Processor::Base
    def initialize
      super :diff_rate,"DiffRate"
    end
    def process val
      val=val.to_f
      ret=nil
      curr_time=Time.now
      if @last_time and curr_time>@last_time
        ret=val/(curr_time-@last_time).to_f
      end
      @last_value=val
      @last_time=curr_time
      ret
    end
  end
end

module LogwatcherAgent

  class Agent < NewRelic::Plugin::Agent::Base

    agent_guid   "DROP_GUID_FROM_PLUGIN_HERE"
    agent_config_options :log_path, :term, :grep_options
    agent_human_labels("Logwatcher") { "#{log_path}" }

    def setup_metrics
      @occurances=NewRelic::Processor::DiffRate.new
    end


    def poll_cycle
      check_params
      @last_length ||= 0
      current_length = `wc -c #{log_path}`.split(' ')[0].to_i
      count = 0

      # don't run it the first time
      if (@last_length > 0 )
        read_length = current_length - @last_length
        # Check to see if this file was rotated. This occurs when the +current_length+ is less than 
        # the +last_run+. Don't return a count if this occured.
        if read_length >= 0
          # finds new content from +last_length+ to the end of the file, then just extracts from the recorded 
          # +read_length+. This ignores new lines that are added after finding the +current_length+. Those lines 
          # will be read on the next run.
          count = `tail -c +#{@last_length+1} #{log_path} | head -c #{read_length} | grep "#{term}" -#{grep_options.to_s.gsub('-','')}c`.strip.to_f
        end
      end
          
      report_metric("Matches/Total", "Occurances", @occurances.process(count)) if count
      @last_length = current_length
    end

    private
    
    def term
      @term || "[Ee]rror"
    end
    
    def check_params
      @log_path = log_path.to_s.strip
      if log_path.empty?
        raise( "Please provide a path to the log file." )
      end

      `test -e #{log_path}`

      unless $?.success?
        raise("Could not find the log file. The log file could not be found at: #{log_path}. Please ensure the full path is correct.")
      end

      @term = term.to_s.strip
      if term.empty?
        raise( "The term cannot be empty" )
      end
    end
  end


  NewRelic::Plugin::Setup.install_agent :logwatcher, LogwatcherAgent

  #
  # Launch the agent (never returns)
  #
  NewRelic::Plugin::Run.setup_and_run

end
