module Pelvis
  class Evocation
    include Logging
    include EM::Deferrable

    def self.start(*args, &block)
      new(*args).start(&block)
    end

    def initialize(outcall, identity)
      @outcall, @identity = outcall, identity
    end
    attr_reader :outcall, :identity

    def start(&block)
      logger.debug "starting evocation: #{@identity.inspect}"
      incall = agent.evoke(self)
      logger.debug "got an incall: #{incall.inspect}"
      incall.callback do |data|
        logger.debug "callback from incall: #{incall.inspect}: #{data.inspect}"
        complete(data)
      end
      incall.errback do |data|
        logger.debug "errback from incall: #{incall.inspect}: #{data.inspect}"
        fail(data)
      end
      @started_at = Time.now
      self
    end

    def receive(data)
      logger.debug "received data from incall: #{data.inspect}"
      @outcall.receive(self, data)
    end

    def agent
      @outcall.agent
    end

    def job
      @outcall.job
    end

    def complete(data)
      @completed_at = Time.now
      succeed(data)
    end

    def complete?
      !!@completed_at
    end

    def duration
      complete? ? @completed_at - @started_at : Time.now - @started_at
    end

    def inspect
      "#<#{self.class} outcall=#{@outcall.inspect} identity=#{@identity.inspect}>"
    end
  end
end
