require 'eventmachine'
require 'hmac-sha2'
require 'extlib'

$:.unshift File.dirname(__FILE__)

require 'pelvis/router'
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
end
