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

        def handle_job_init(stanza, node, token)
          args = JSON.parse(Base64.decode64(node.content)).to_mash
          job = Job.new(token, node["scope"], node["operation"], args, {})
          logger.debug "Job starting: #{job.inspect}"
          incall = @protocol.agent.invoke(@identity, job)
          incall.on_initialized do
            send_result(stanza)
          end
          incall.on_begun do
            send_job_begin(job.token) do |reply|
              incall.begin
            end
          end
          incall.on_received do |data|
            send_job_data(job.token, data) do |reply|
              puts "Data was received"
            end
          end
          incall.on_completed do |event|
            send_job_end(job.token) do |reply|
              puts "End was received"
            end
          end
          incall.on_failed do |error|
            logger.error "got an error for token: #{token}"
            send_error(job.token, error)
          end
          incall
        end

        def handle_job_begin(stanza, node, token)
          incall_for(token).handle_begin(stanza)
        end

        def handle_job_data(stanza, node, token)
          data = JSON.parse(Base64.decode64(node.content)).to_mash
          incall_for(token).receive(data)
        end

        def handle_job_end(stanza, node, token)
          incall_for(token).complete
        end

        def handle_result(stanza, node, token)
          block, original = outbounds.delete(stanza.id)
          if block
            block.call(stanza)
          else
            puts "Ignoring result: #{stanza.inspect}"
          end
        end

        def handle_error(stanza, node, token)
          block, original = outbounds.delete(stanza.id)
          if block
            block.call(stanza)
          else
            puts "Ignoring error: #{stanza.inspect}"
          end
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

        def send_job_init(token, scope, operation, args, &block)
          send_stanza(:set, "init", args, :token => token, :scope => scope, :operation => operation, &block)
        end

        def send_job_begin(token, &block)
          send_stanza(:set, "begin", nil, :token => token, &block)
        end

        def send_job_data(token, data, &block)
          send_stanza(:set, "data", data, :token => token, &block)
        end

        def send_job_end(token, &block)
          send_stanza(:set, "end", nil, :token => token, &block)
        end

        def send_result(stanza)
          reply = stanza.reply
          reply.attributes[:type] = :result
          @protocol.stream.send(reply)
        end

        def send_error(stanza, error, &block)
          reply = stanza.reply
          reply.attributes[:type] = :error
          node = XML::Node.new("error")
          node.attributes[:code] = 500
          node << XML::Node.new_cdata(error) if error
          reply << node
          @protocol.stream.send(reply)
        end

        def send_stanza(iq_type, type, content, attributes, &block)
          node = XML::Node.new("job")
          node.attributes[:type] = type
          attributes.each do |key,value|
            node.attributes[key] = value
          end
          node << XML::Node.new_cdata(Base64.encode64(content.to_json)) if content
          iq = Blather::Stanza::Iq.new(iq_type, @identity)
          iq << node
          outbounds[iq.id] = [block, iq]
          @protocol.stream.send(iq)
        end

        def outbounds
          @outbounds ||= {}
        end
      end
    end
  end
end
