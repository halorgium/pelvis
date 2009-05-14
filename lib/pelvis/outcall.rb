module Pelvis
  class Outcall
    include Logging
    include EM::Deferrable

    def self.start(*args)
      new(*args).start
    end

    def initialize(agent, job)
      @agent, @job = agent, job
    end
    attr_reader :agent, :job

    def start
      logger.debug "starting outcall on #{@agent.identity}: #{inspect}"
      discover
      self
    end

    def evoke(identity)
      e = Evocation.start(self, identity)
      evocations << e
      e.callback do |r|
        logger.debug "callback from #{identity}: #{r.inspect}"
        check_complete
      end
      e.errback do |r|
        logger.debug "errback from #{identity}: #{r.inspect}"
        check_complete
      end
    end

    def receive(evocation, data)
      logger.debug "data from #{evocation.inspect}: #{data.inspect}"
      @job.receive(data)
    end

    def check_complete
      return if complete?
      if evocations.all? {|e| e.complete?}
        logger.debug "All evocations are complete"
        @complete = true
        @job.complete("win")
        succeed "Done at #{Time.now}"
      end
    end

    def complete?
      @complete
    end

    def evocations
      @evocations ||= []
    end

    def evoke_to(identities)
      identities.each do |i|
        evoke(i)
      end
      check_complete
    end

    def discover
      if identities = @job.options[:identities]
        evoke_to(identities)
      else
        raise "Disabled herault, provide identities to the job"
        discover_with_herault
      end
    end

    class HeraultDiscoverer
      include Delegate

      def initialize(outcall)
        @outcall = outcall
        @identities = []
      end

      def receive(data)
        @identities += data[:identities]
      end

      def complete(data)
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
