module Pelvis
  module Protocols
    class XMPP
      class RemoteAgent
        include Logging

        def initialize(protocol, identity)
          @protocol, @identity = protocol, identity
        end
        attr_reader :identity

        def evoke(job)
          create_incall_for(job)
        end

        def invoke(token, node)
          args = JSON.parse(Base64.decode64(node.content)).to_mash
          job = Job.new(token, node["scope"], node["operation"], args, {:delegate => DefaultDelegate.new})
          logger.debug "Job starting: #{job.inspect}"
          incall = @protocol.agent.invoke(@identity, job)
          incall.on_received do |data|
            send_data(job.token, data)
          end
          incall.on_completed do |event|
            send_final(job.token)
          end
          incall.on_failed do |error|
            logger.error "got an error for token: #{token}"
            send_error(job.token)
          end
          incall
        end

        def receive(token, node)
          data = JSON.parse(Base64.decode64(node.content)).to_mash
          incall_for(token).receive(data)
        end

        def complete(token, node)
          incall_for(token).complete
        end

        def incall_for(token)
          incalls[token]
        end

        def create_incall_for(job)
          incall = Incall.new(self, job)
          incalls[job.token] = incall
          incall.start
          incall
        end

        def incalls
          @incalls ||= {}
        end

        def send_init(token, scope, operation, args)
          send_stanza("init", args, :scope => scope, :token => token, :operation => operation)
        end

        def send_data(token, data)
          send_stanza("data", data, :token => token)
        end

        def send_final(token)
          send_stanza("final", nil, :token => token)
        end

        def send_stanza(type, content, attributes)
          node = XML::Node.new("job")
          node.attributes[:type] = type
          attributes.each do |key,value|
            node.attributes[key] = value
          end
          node << XML::Node.new_cdata(Base64.encode64(content.to_json)) if content
          iq = Blather::Stanza::Iq.new(:set, @identity)
          iq << node
          @protocol.stream.send(iq)
        end
      end
    end
  end
end
