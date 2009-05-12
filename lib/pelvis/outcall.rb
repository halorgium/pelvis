module Pelvis
  class Outcall
    include EM::Deferrable

    def self.start(*args)
      new(*args).start
    end

    def initialize(agent, job)
      @agent, @job = agent, job
    end
    attr_reader :agent, :job

    def start
      LOGGER.debug "starting outcall on #{@agent.identity}: #{inspect}"
      discover
      self
    end

    def evoke(identity)
      e = Evocation.start(self, identity)
      evocations << e
      e.callback do |r|
        LOGGER.debug "callback from #{identity}: #{r.inspect}"
        check_complete
      end
      e.errback do |r|
        LOGGER.debug "errback from #{identity}: #{r.inspect}"
        check_complete
      end
    end

    def receive(evocation, data)
      LOGGER.debug "data from #{evocation.inspect}: #{data.inspect}"
      @job.receive(data)
    end

    def check_complete
      return if complete?
      if evocations.all? {|e| e.complete?}
        LOGGER.debug "All evocations are complete"
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
        discover_with_herault
      end
    end

    def discover_with_herault
      @agent.request(:direct, "/security/discover",
                     {:operation => job.operation, :args => job.args},
                     {:identities => [@agent.herault]},
                     self) do
        def receive(data)
          @identities ||= []
          @identities += data[:identities]
        end

        def complete(data)
          return unless @identities
          parent.evoke_to(@identities)
        end
      end
    end

    def inspect
      "#<#{self.class} agent=#{@agent.inspect} " \
        "token=#{@job.token.inspect} operation=#{@job.operation.inspect} " \
        "args=#{@job.args.inspect} options=#{@job.options.inspect}>"
    end
  end
end
