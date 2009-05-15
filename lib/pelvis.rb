require 'eventmachine'
require 'hmac-sha2'
require 'extlib'

$:.unshift File.dirname(__FILE__)

require 'pelvis/logging'
require 'pelvis/job'
require 'pelvis/delegate'
require 'pelvis/agent'
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
    @logger ||= Logger.new($stderr)
  end

  def self.connect(protocol_name, protocol_options, &block)
    Protocols.connect(protocol_name, protocol_options, &block)
  end
end
