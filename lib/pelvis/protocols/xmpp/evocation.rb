module Pelvis
  module Protocols
    class XMPP
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
