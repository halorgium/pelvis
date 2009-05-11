require 'eventmachine'
require 'hmac-sha2'

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

require 'logger'

module Pelvis
  LOGGER = Logger.new($stderr)
end
