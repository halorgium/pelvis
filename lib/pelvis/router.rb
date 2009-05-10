module Pelvis
  class Router
    include EM::Deferrable

    def self.start(&block)
      new.start(&block)
    end

    def start(&block)
      EM.run do
        yield self if block_given?
      end
    end

    def agent(identity)
      agent = Agent.start(self, identity)
      local_agents << agent
      agent
    end

    # TODO: This need to support other protocols like AMQP, XMPP
    def deliver_to(identity, type, message)
      type = type.to_sym
      unless [:init].include?(type)
        LOGGER.debug "Unknown type: #{type.inspect}"
        return
      end

      if agent = local_agent_for(identity)
        agent.receive(type, message)
      else
        raise "Remote sending has not been implemented"
      end
    end

    def local_agent_for(identity)
      @local_agents.find do |agent|
        agent.identity == identity
      end
    end

    def local_agents
      @local_agents ||= []
    end

    def inspect
      "#<#{self.class} local_agents=#{local_agents.size}>"
    end
  end
end
