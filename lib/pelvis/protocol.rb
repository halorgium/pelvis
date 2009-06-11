module Pelvis
  class Protocol
    include Logging
    extend Callbacks

    def self.register(name)
      @registered_as = name.to_sym
      Protocols.available[name.to_sym] = self
    end

    def self.registered_as
      @registered_as
    end

    callbacks :connected, :spawned, :failed

    def initialize(options, &block)
      @options = {:advertise => true}.merge(options)
      @configure_block = block
      on_connected do
        spawn
      end
      on_failed do |error|
        logger.error "Connection Error: #{error}"
      end
    end
    attr_reader :options, :agent

    def start
      connect
    end

    def spawn
      logger.debug "Connected to protocol: #{inspect}"
      @agent = Agent.start(self)
      spawned(@agent)
      @configure_block.call(@agent)
      @agent.advertise
    end

    def advertise?
      options[:advertise]
    end

    def connect
      raise "Implement #connect on #{self.class}"
    end

    def evoke(job)
      raise "Implement #evoke on #{self.class}"
    end

    def identity
      raise "Implement #identity on #{self.class}"
    end

    def herault
      raise "Implement #herault on #{self.class}"
    end

    def inspect
      "#<#{self.class} name=#{self.class.registered_as.inspect} options=#{@options.inspect}>"
    end
  end
end
