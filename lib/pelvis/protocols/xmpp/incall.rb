module Pelvis
  module Protocols
    class XMPP
      class Incall
        include Logging
        include EM::Deferrable

        def initialize(agent, evocation)
          @agent, @evocation = agent, evocation
        end

        def start
          @agent.send_init(job.token, job.scope, job.operation, job.args)
          self
        end

        def receive(data)
          logger.debug "received data: #{data.inspect}"
          @evocation.receive(data)
        end

        def complete
          succeed("completed: #{job.token}")
        end

        def job
          @evocation.job
        end
      end
    end
  end
end
