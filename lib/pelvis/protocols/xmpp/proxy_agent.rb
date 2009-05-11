require 'json'
require 'base64'

module Pelvis
  module Protocols
    class XMPP
      class ProxyAgent
        def initialize(protocol, identity)
          @protocol, @identity = protocol, identity
        end
        attr_reader :identity

        def evoke(evocation)
          create_incall_for(evocation)
        end

        def invoke(token, node)
          args = JSON.parse(Base64.decode64(node.content)).to_mash
          job = Job.new(token, node["operation"], args, {}, nil)
          LOGGER.debug "Job starting: #{job.inspect}"
          incall = @protocol.agent.invoke(evocation_for(job))
          incall.callback do |r|
            send_final(job.token)
          end
          incall.errback do |r|
            LOGGER.error "got an error for token: #{token}"
          end
        end

        def receive(token, node)
          data = JSON.parse(Base64.decode64(node.content)).to_mash
          incall_for(token).receive(data)
        end

        def complete(token, node)
          incall_for(token).complete
        end

        def evocation_for(job)
          evocations[job.token] ||= Evocation.new(self, job)
        end

        def evocations
          @evocations ||= {}
        end

        def incall_for(token)
          incalls[token]
        end

        def create_incall_for(evocation)
          incall = Incall.new(self, evocation)
          incalls[evocation.job.token] = incall
          incall.start
        end

        def incalls
          @incalls ||= {}
        end

        def send_init(token, operation, args)
          send_stanza("init", args, :token => token, :operation => operation, :scope => "all")
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

        class Incall
          include EM::Deferrable

          def initialize(agent, evocation)
            @agent, @evocation = agent, evocation
          end

          def start
            @agent.send_init(job.token, job.operation, job.args)
            self
          end

          def receive(data)
            LOGGER.debug "received data: #{data.inspect}"
            @evocation.receive(data)
          end

          def complete
            succeed("completed: #{job.token}")
          end

          def job
            @evocation.job
          end
        end

        class Evocation
          def initialize(agent, job)
            @agent, @job = agent, job
          end
          attr_reader :agent, :job

          def receive(data)
            @agent.send_data(job.token, data)
          end

          def identity
            @agent.identity
          end
        end
      end
    end
  end
end
