module Pelvis
  module Protocols
    class XMPP
      class Incall
        include Logging
        extend Callbacks

        callbacks :received, :completed, :failed

        def initialize(agent, job)
          @agent, @job = agent, job
        end
        attr_reader :job

        def start
          @agent.send_init(job.token, job.scope, job.operation, job.args)
        end

        def receive(data)
          logger.debug "received data: #{data.inspect}"
          received(data)
        end

        def complete
          completed("done")
        end
      end
    end
  end
end
