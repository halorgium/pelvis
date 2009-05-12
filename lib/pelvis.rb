require 'eventmachine'
require 'hmac-sha2'
require 'extlib'

$:.unshift File.dirname(__FILE__)

require 'pelvis/agent'
require 'pelvis/job'
require 'pelvis/actor'

require 'pelvis/outcall'
require 'pelvis/evocation'

require 'pelvis/incall'
require 'pelvis/invocation'

require 'pelvis/protocol'
require 'pelvis/protocols'
require 'pelvis/protocols/local'
require 'pelvis/protocols/xmpp'
require 'pelvis/protocols/xmpp/proxy_agent'

require 'logger'

module Pelvis
  LOGGER = Logger.new($stderr)

  def self.connect(protocol_name, protocol_options, actors = nil, &block)
    protocol = Protocols.connect(protocol_name, self, protocol_options, actors)
    protocol.callback(&block) if block_given?
    protocol.errback do |r|
      LOGGER.error "Could not connect to protocol: #{protocol.inspect}, #{r.inspect}"
    end
    protocol
  end
end
