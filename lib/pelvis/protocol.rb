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

    def initialize(router, options, *args_for_agent)
      @router, @options, @args_for_agent = router, options, args_for_agent
    end
    attr_reader :router, :options, :agent

    def spawn
      LOGGER.debug "Connected to protocol: #{inspect}"
      @agent = Agent.start(self, *@args_for_agent)
      on_spawn(@agent)
      @agent.callback do |r|
        succeed(@agent)
      end
    end

    def evoke(job)
      raise "Implement #evoke on #{self.class}"
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

    def inspect
      "#<#{self.class} name=#{self.class.registered_as.inspect} options=#{@options.inspect}>"
    end
  end
end
