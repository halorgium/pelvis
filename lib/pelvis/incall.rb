module Pelvis
  class Incall
    include EM::Deferrable

    def self.start(*args)
      new(*args).start
    end

    def initialize(agent, evocation)
      @agent, @evocation = agent, evocation
    end
    attr_reader :agent, :evocation

    def start
      LOGGER.debug "starting incall on #{@agent.identity}: #{@evocation.inspect}"
      # TODO: This needs to authorize the job
      operations.each do |o|
        invoke(*o)
      end
      check_complete
      self
    end

    def invoke(actor_klass, operation)
      i = Invocation.start(self, actor_klass, operation)
      invocations << i
      i.callback do |r|
        LOGGER.debug "callback from #{operation}: #{r.inspect}"
        check_complete
      end
      i.errback do |r|
        LOGGER.debug "errback from #{operation}: #{r.inspect}"
        check_complete
      end
    end

    def receive(invocation, data)
      LOGGER.debug "data from #{invocation.inspect}: #{data.inspect}"
      @evocation.receive(data)
    end

    def check_complete
      return if complete?
      if invocations.all? {|e| e.complete?}
        LOGGER.debug "All invocations are finished"
        @complete = true
        succeed "Done at #{Time.now}"
      end
    end

    def complete?
      @complete
    end

    def job
      @evocation.job
    end

    def invocations
      @invocations ||= []
    end

    def operations
      @agent.operations_for(job)
    end

    def inspect
      "#<#{self.class} agent=#{agent.inspect} evocation=#{evocation.inspect}>"
    end
  end
end
