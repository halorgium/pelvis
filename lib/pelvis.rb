gem 'eventmachine', '>= 0.12.7'
require 'eventmachine'
require 'json'
require 'extlib'

$:.unshift File.dirname(__FILE__)

require 'pelvis/logging'
require 'pelvis/callbacks'

require 'pelvis/job'
require 'pelvis/delegate'
require 'pelvis/agent'
require 'pelvis/advertiser'
require 'pelvis/actor'

require 'pelvis/message'
require 'pelvis/outcall'
require 'pelvis/evocation'

require 'pelvis/incall'
require 'pelvis/invocation'

require 'pelvis/protocol'
require 'pelvis/protocols'
require 'pelvis/protocols/local'

require 'logger'

module Pelvis
  def self.logger
    @logger ||= begin
      l = Logger.new($stderr)
      l.level = Logger::WARN
      l
    end
  end

  def self.connect(name, options, &block)
    Protocols.start(name, options, &block)
  end
end
