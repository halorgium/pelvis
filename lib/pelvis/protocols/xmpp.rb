require 'blather'
require 'json'
require 'base64'
require 'resolv'

module Pelvis
  module Protocols
    class XMPP < Protocol
      class ConnectionError < RuntimeError; end

      register :xmpp

      def connect
        logger.debug "connecting using #{self.class}: #{options.inspect}"
        host = jid.domain if jid.domain == 'localhost'

        @stream = Blather::Stream::Client.start(self, jid, options[:password],host)
        self
      end
      attr_reader :stream

      def post_init
        stream.send Blather::Stanza::Presence::Status.new
        connected
      end

      def unbind
        logger.warn "Got disconnected (unbind)"
        failed(ConnectionError.new("got disconnected"))
      end

      def close
        logger.warn "Got disconnected (close)"
        connect
      end

      def receive_data(stanza)
        logger.debug "got a stanza for #{identity}:\n#{stanza.inspect}"

        case stanza
          when Blather::BlatherError, Blather::SASLError
            failed stanza
            return
          when Blather::Stanza::Iq::Roster
            # ignore
          when Blather::Stanza::Presence::Status
            logger.debug "Got presence announcement from #{stanza.from}"
            if presence_handlers[stanza.from.to_s]
              presence_handlers[stanza.from.to_s].call stanza.from, stanza.state
            end
          when Blather::Stanza::Presence::Subscription
            if stanza.subscribe?
              logger.debug "Got subscription request from #{stanza.from}"
              val = if stanza.from.stripped == herault_jid.stripped
                      logger.warn "Approving subscription request from #{stanza.from}"
                      stanza.approve!
                    else
                      logger.warn "Refusing subscription request from #{stanza.from}"
                      stanza.refuse!
                    end
              stream.send val
            end
          else
            process_stanza stanza
        end
      end

      def process_stanza(stanza)
        remote_agent = agent_for(stanza['from'])
        node = stanza.find("job").first
        token = node["token"]

        type = node["type"]
        unless %w( init begin data end error ).include?(type)
          raise "Unable to handle job XML of type: #{type.inspect}"
        end

        case stanza["type"]
        when "set"
          remote_agent.send("handle_job_#{type}", stanza, node, token)
        when "result"
          remote_agent.handle_result(stanza, node, token)
        when "error"
          remote_agent.handle_error(stanza, node, token)
        else
          raise "Unable to handle weird IQ with type: #{stanza["type"].inspect}"
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
        "herault@#{jid.domain}/agent"
      end

      def herault_jid
        @herault_jid = Blather::JID.new(herault)
      end

      def handle_subscribe_presence(ident)
        logger.debug "#{identity} Subscribing to presence announcements for #{ident}"
        stream.send Blather::Stanza::Presence::Subscription.new(ident, :subscribe)
      end
    end
  end
end

require 'pelvis/protocols/xmpp/remote_agent'
require 'pelvis/protocols/xmpp/incall'
