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

        # Graciously stolen from xmpp4r
        if host.nil?
          begin
            srv = []
            Resolv::DNS.open { |dns|
              # If ruby version is too old and SRV is unknown, this will raise a NameError
              # which is caught below
              logger.debug "RESOLVING:\n_xmpp-client._tcp.#{jid.domain} (SRV)"
              srv = dns.getresources("_xmpp-client._tcp.#{jid.domain}", Resolv::DNS::Resource::IN::SRV)
            }
            # Sort SRV records: lowest priority first, highest weight first
            srv.sort! { |a,b| (a.priority != b.priority) ? (a.priority <=> b.priority) : (b.weight <=> a.weight) }

            srv.each { |record|
              begin
                logger.debug "Attempting connection to #{record.target}:#{record.port}"
                @stream = Blather::Stream::Client.start(self, jid, options[:password], record.target.to_s, record.port)
                # Success
                return self
              rescue
                # Try next SRV record
              end
            }
          rescue NameError
            logger::debug "Resolv::DNS does not support SRV records. Please upgrade to ruby-1.8.3 or later!"
          end
        end

        @stream = Blather::Stream::Client.start(self, jid, options[:password])
        self
      end
      attr_reader :stream

      def post_init
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

        if stanza.is_a?(Blather::BlatherError) || stanza.is_a?(Blather::SASLError)
          failed stanza
          return
        end

        from = stanza["from"]
        remote_agent = agent_for(from)
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
    end
  end
end

require 'pelvis/protocols/xmpp/remote_agent'
require 'pelvis/protocols/xmpp/incall'
