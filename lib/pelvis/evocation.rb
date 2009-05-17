module Pelvis
  class Evocation
    include Logging
    extend Callbacks

    callbacks :received, :completed, :failed

    def initialize(outcall, identity)
      @outcall, @identity = outcall, identity
      @initialized, @begun = nil, nil
    end
    attr_reader :outcall, :identity

    def start
      logger.debug "starting evocation: #{@identity.inspect}"
      @incall = agent.evoke(@identity, job)
      @incall.on_initialized do
        logger.debug "incall initialized: #{@identity.inspect}"
        @initialized = true
        reply
      end
      @incall.on_begun do
        logger.debug "incall begun: #{@identity.inspect}"
        @begun = true
        reply
      end
      @incall.on_received do |data|
        logger.debug "incall received: #{@identity.inspect}: #{data.inspect}"
        received(data)
      end
      @incall.on_completed do |event|
        logger.debug "incall completed: #{@identity.inspect}: #{event.inspect}"
        finish
        completed(event)
      end
      @incall.on_failed do |error|
        logger.debug "incall failed: #{@identity.inspect}: #{error.inspect}"
        finish
        failed(error)
      end
      @started_at = Time.now
    end

    def reply
      if @initialized && @begun
        @incall.begin
      end
    end

    def agent
      @outcall.agent
    end

    def job
      @outcall.job
    end

    def finish
      @finished_at = Time.now
    end

    def finished?
      @finished_at
    end

    def duration
      finished? ? @finished_at - @started_at : Time.now - @started_at
    end

    def inspect
      "#<#{self.class} outcall=#{@outcall.inspect} identity=#{@identity.inspect}>"
    end
  end
end
