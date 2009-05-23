module Pelvis
  module Protocols
    class XMPP
      class Incall
        include Logging
        extend Callbacks

        callbacks :initialized, :begun, :received, :completed, :failed

        def initialize(agent, job)
          @agent, @job = agent, job
        end
        attr_reader :job

        def start
          @agent.send_job_init(job.token, job.scope, job.operation, job.args) do |reply|
            if reply.error?
              failed(reply)
            else
              initialized
            end
          end
        end

        def handle_begin(stanza)
          @begin_stanza = stanza
          begun
        end

        def begin
          @agent.send_result(@begin_stanza)
        end

        def receive(data)
          logger.debug "received data: #{data.inspect}"
          received(data)
        end

        def complete
          completed("done")
        end

        def fail(error)
          failed(error)
        end

        def put(data)
          @agent.send_job_data(job.token, data) do |reply|
            # TODO: what to do with errors here?
          end
        end
      end
    end
  end
end
