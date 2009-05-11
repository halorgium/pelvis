module Pelvis
  class Protocol
    include EM::Deferrable

    def self.register(name)
      @registered_as = name.to_sym
      Protocols.available[name.to_sym] = self
    end

    def self.registered_as
      @registered_as
    end

    def self.connect(*args)
      p = new(*args)
      p.connect
      p
    end

    def initialize(router, options)
      @router, @options = router, options
    end
    attr_reader :router, :options

    def spawn(*args)
      agent = Agent.start(self, *args)
      on_spawn(agent)
      agent
    end

    def deliver_to(identity, type, message)
      type = type.to_sym
      unless [:init].include?(type)
        LOGGER.debug "Unknown type: #{type.inspect}"
        return
      end

      if agent = agent_for(identity)
        agent.receive(type, message)
      else
        raise "No such agent found: #{identity.inspect}"
      end
    end

    def connect
      raise "Implement #connect on #{self.class}"
    end

    def identity
      raise "Implement #identity on #{self.class}"
    end

    def herault
      raise "Implement #herault on #{self.class}"
    end

    def on_spawn(agent)
    end

    def agent_for(identity)
      raise "Implement #agent_for on #{self.class}"
    end

    def inspect
      "#<#{self.class} name=#{self.class.registered_as.inspect} options=#{@options.inspect}>"
    end
  end
end
