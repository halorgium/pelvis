require 'blather'
require 'json'
require 'base64'

module Pelvis
  module Protocols
    class XMPP < Protocol
      register :xmpp

      def connect
        logger.debug "connecting using #{self.class}: #{options.inspect}"
        @stream = Blather::Stream::Client.start(self, jid, options[:password])
      end
      attr_reader :stream

      def stream_started(stream)
        spawn
      end

      def stopped
        logger.warn "Got disconnected"
        failed "disconnected"
      end

      def call(stanza)
        logger.debug "got a stanza for #{identity}:\n#{stanza.inspect}"
        if stanza.is_a?(Blather::SASLError)
          failed stanza.message
          return
        end
        remote_agent = agent_for(stanza["from"])
        node = stanza.find("job").first
        token = node["token"]
        case node["type"]
        when "init"
          remote_agent.invoke(token, node)
        when "data"
          remote_agent.receive(token, node)
        when "final"
          remote_agent.complete(token, node)
        else
          raise "Unable to handle job XML of type: #{node['type'].inspect}"
        end
      end

      def evoke(identity, job)
        agent_for(identity).evoke(job)
      end

      def agent_for(identity)
        agents[identity] ||= RemoteAgent.new(self, identity)
      end

      def agents
        @agents ||= {}
      end

      def jid=(jid)
      end

      def jid
        Blather::JID.new(identity)
      end

      def identity
        options[:jid] || raise("XMPP protocol needs an JID")
      end

      def herault
        "herault@localhost/agent"
      end

      def advertise?
        identity != herault
      end
    end
  end
end

require 'pelvis/protocols/xmpp/remote_agent'
require 'pelvis/protocols/xmpp/incall'
require 'pelvis/protocols/xmpp/evocation'
