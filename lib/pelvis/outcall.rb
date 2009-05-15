module Pelvis
  class Outcall
    include Logging
    extend Callbacks

    callbacks :received, :completed, :failed

    def initialize(agent, job)
      @agent, @job = agent, job
    end
    attr_reader :agent, :job

    def start
      logger.debug "starting outcall on #{@agent.identity}: #{inspect}"
      discover
    end

    def evoke(identity)
      e = Evocation.start(self, identity)
      evocations << e
      e.on_received do |data|
        logger.debug "outcall received: #{identity}: #{data.inspect}"
        received(data)
      end
      e.on_completed do |event|
        logger.debug "outcall completed: #{identity}: #{event.inspect}"
        check_complete
      end
      e.on_failed do |error|
        logger.debug "outcall failed: #{identity}: #{error.inspect}"
        finish
        check_complete
        failed(error)
      end
    end

    def check_complete
      return if finished?
      if evocations.all? {|e| e.finished?}
        logger.debug "All evocations are finished"
        finish
        completed "Done at #{Time.now}"
      end
    end

    def finish
      @finished_at = Time.now
    end

    def finished?
      @finished_at
    end

    def evocations
      @evocations ||= []
    end

    def evoke_to(identities)
      if job.scope == :all
        identities.each do |i|
          evoke(i)
        end
      elsif job.scope == :direct
        to = identities[rand(identities.size)]
        evoke(to)
      elsif job.scope == :init
        raise "TODO: I have nfi what this scope does"
      else
        raise "Invalid scope #{job.scope} detected"
      end
      check_complete
    end

    def discover
      if identities = @job.options[:identities]
        evoke_to(identities)
      else
        discover_with_herault
      end
    end

    class HeraultDiscoverer
      include SafeDelegate

      def initialize(outcall)
        @outcall = outcall
        @identities = []
      end

      def received(data)
        @identities += data[:identities]
      end

      def completed(data)
        @outcall.evoke_to(@identities)
      end
    end

    def discover_with_herault
      @agent.request(:direct, "/security/discover", {:operation => job.operation, :args => job.args},
                     :identities => [@agent.herault], :delegate => HeraultDiscoverer.new(self))
    end

    def inspect
      "#<#{self.class} agent=#{@agent.inspect} " \
        "token=#{@job.token.inspect} operation=#{@job.operation.inspect} " \
        "args=#{@job.args.inspect} options=#{@job.options.inspect}>"
    end
  end
end
