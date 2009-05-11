if blather_dir = ENV["BLATHER_DIR"]
  $:.unshift blather_dir + "/lib"
end
require 'blather'

module Pelvis
  module Protocols
    class XMPP < Protocol
      register :xmpp

      def connect
        LOGGER.debug "connecting using #{self.class}: #{options.inspect}"
        @stream = Blather::Stream::Client.start(self, jid, options[:password])
      end
      attr_reader :stream

      def stream_started(stream)
        spawn
      end

      def call(stanza)
        LOGGER.debug "got a stanza for #{identity}: #{stanza.inspect}"
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

      def evoke(evocation)
        agent_for(evocation.identity).evoke(evocation)
      end

      def agent_for(identity)
        agents[identity] ||= ProxyAgent.new(self, identity)
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
